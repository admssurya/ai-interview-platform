# frozen_string_literal: true

# Read-only reference to the existing rakamin-api organizations table.
# Lives in the PostgreSQL public schema (excluded from Apartment in rakamin-api).
# We connect to the same DB so this table is directly accessible.
#
# Only includes the fields we need for tenant resolution.
class Organization < ApplicationRecord
  self.table_name = 'organizations'

  ORG_CACHE_VERSION_KEY = 'organizations:cache_version'
  # Tenant identifiers come from client-controlled headers/referers. Only
  # cache well-formed identifiers to prevent Redis key flooding from
  # arbitrary probe traffic; anything else bypasses the cache.
  CACHEABLE_IDENTIFIER_FORMAT = /\A[a-z0-9._-]{1,100}\z/i

  after_commit :bump_cache_version

  # Mirrors rakamin-api Organisation.identify exactly.
  # Accepts identifier, name, scheme, or host.
  #
  # Cached per-request-input with a generation version: any insert/update/
  # destroy bumps the version so stale entries are never served after a data
  # change (they simply expire unused). Worst-case staleness is bounded by
  # the version-key TTL, not the entry TTL.
  def self.identify(identifier)
    return default_organization if identifier.blank?

    unless cacheable_identifier?(identifier)
      return uncached_identify(identifier)
    end

    Rails.cache.fetch(cache_key(identifier), expires_in: 5.minutes) do
      uncached_identify(identifier)
    end || default_organization
  end

  def self.uncached_identify(identifier)
    sql_string = <<~SQL.squish
      (? IN (identifier, name, scheme, host)) OR
      (alias_hosts && ARRAY[?]::varchar[])
    SQL

    where(sql_string, identifier, Array(identifier)).first ||
      default_organization
  end

  def self.cacheable_identifier?(identifier)
    identifier.to_s.match?(CACHEABLE_IDENTIFIER_FORMAT)
  end

  def self.cache_key(identifier)
    "org:v#{cache_version}:#{identifier}"
  end

  # Generation token for cache invalidation. Deleting the version key forces
  # every process to generate a new one on next read, orphaning all old
  # entries at once — no per-key bookkeeping, no cross-process races on the
  # entries themselves.
  def self.cache_version
    Rails.cache.fetch(ORG_CACHE_VERSION_KEY, expires_in: 10.minutes) do
      SecureRandom.uuid
    end
  end

  def self.bump_cache_version
    Rails.cache.delete(ORG_CACHE_VERSION_KEY)
  end

  def self.default_organization
    where(id: 0).first
  end

  # Convenience: is this the system default org?
  def default?
    id.zero?
  end

  private

  def bump_cache_version
    Organization.bump_cache_version
  end
end
