# frozen_string_literal: true

require "test_helper"

class AdressevaelgerVersionTest < Minitest::Test
  def test_version_is_set
    assert Adressevaelger::VERSION.match?(/\A\d+\.\d+\.\d+\z/)
  end
end
