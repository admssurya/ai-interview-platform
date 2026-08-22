# frozen_string_literal: true

class SkillTaxonomy < ApplicationRecord
  validates :skill_id,    presence: true, uniqueness: true, length: { maximum: 50 }
  validates :skill_label, presence: true, length: { maximum: 255 }
  validates :category,    presence: true, length: { maximum: 50 }
  validates :l1_anchor,   presence: true
  validates :l2_anchor,   presence: true
  validates :l3_anchor,   presence: true
  validates :l4_anchor,   presence: true
  validates :l5_anchor,   presence: true

  CATEGORIES = %w[engineering soft_skills product_process].freeze

  CACHE_VERSION_KEY = 'skill_taxonomies:cache_version'

  after_commit :bump_cache_version

  # Generation token for endpoint caching (see SkillTaxonomiesController).
  # Any insert/update/destroy orphans all cached lists at once, so clients
  # never see a mix of old and new taxonomy data after a change.
  def self.cache_version
    Rails.cache.fetch(CACHE_VERSION_KEY, expires_in: 1.hour) do
      SecureRandom.uuid
    end
  end

  def self.bump_cache_version
    Rails.cache.delete(CACHE_VERSION_KEY)
  end

  private

  def bump_cache_version
    SkillTaxonomy.bump_cache_version
  end
end
