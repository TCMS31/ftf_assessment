# frozen_string_literal: true

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Stubs must match the real object's interface, so a renamed method fails
    # the suite instead of silently passing against a stale double.
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'tmp/rspec_examples.txt'

  # Random order surfaces order dependencies; the seed is printed so a failure
  # can be reproduced exactly.
  config.order = :random
  Kernel.srand config.seed
end
