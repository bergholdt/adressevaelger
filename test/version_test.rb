# frozen_string_literal: true

require "test_helper"

class AdressevaelgerVersionTest < Minitest::Test
  def test_version_is_set
    assert_match(/\A\d+\.\d+\.\d+\z/, Adressevaelger::VERSION)
  end
end
