# frozen_string_literal: true

module Api
  module V1
    class SkillTaxonomiesController < ApiController
      authorize_auth_token! :assessor

      # GET /api/v1/skill_taxonomies
      def index
        skills = SkillTaxonomy.order(:skill_id)
        skills = skills.where(category: params[:category]) if params[:category].present?

        json_response(skill_taxonomies: serialize(skills, with: SkillTaxonomySerializer))
      end

      # GET /api/v1/skill_taxonomies/:skill_id
      def show
        skill = SkillTaxonomy.find_by!(skill_id: params[:skill_id])
        json_response(skill: SkillTaxonomySerializer.new(skill).as_json)
      rescue ActiveRecord::RecordNotFound
        json_error("Skill not found", :not_found)
      end

      private

    end
  end
end
