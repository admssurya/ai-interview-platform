# frozen_string_literal: true

# spec/support/tenant_helpers.rb
module TenantHelpers
  def with_tenant(tenant_id = 1, &block)
    old_tenant_id = Current.tenant_id
    Current.tenant_id = tenant_id
    if block_given?
      yield
    end
  ensure
    Current.tenant_id = old_tenant_id || 1
  end
end

RSpec.configure do |config|
  config.include TenantHelpers, type: :request
  config.include TenantHelpers, type: :model
end