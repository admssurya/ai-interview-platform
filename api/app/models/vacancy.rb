# frozen_string_literal: true

class Vacancy < ApplicationRecord
  include TenantScoped

  has_many :vacancy_skills, dependent: :destroy
  has_many :fit_gap_reports, dependent: :destroy

  validates :role_title, presence: true

  accepts_nested_attributes_for :vacancy_skills,
                                 allow_destroy: true,
                                 reject_if: :all_blank

  # Generation token for index endpoint caching (same pattern as Assessment).
  INDEX_CACHE_VERSION_KEY = 'vacancies:index_cache_version'

  after_commit :bump_index_cache_version

  def self.index_cache_version
    Rails.cache.fetch(INDEX_CACHE_VERSION_KEY, expires_in: 10.minutes) do
      SecureRandom.uuid
    end
  end

  def self.bump_index_cache_version
    Rails.cache.delete(INDEX_CACHE_VERSION_KEY)
  end

  private

  def bump_index_cache_version
    Vacancy.bump_index_cache_version
  end
end
