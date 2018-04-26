require 'test_helper'

class TransactionFileTest < ActiveSupport::TestCase
  def setup
    @user = users(:billing_admin)
    Thread.current[:current_user] = @user

    @regime = regimes(:cfd)
    @sroc_file = @regime.transaction_files.create!(user: @user,
                                                   region: 'A',
                                                   retrospective: false)
    @retro_file = @regime.transaction_files.create!(user: @user,
                                                    region: 'B',
                                                    retrospective: true)
  end

  def test_file_id_ends_with_t_for_sroc_charges
    assert_match /\A\d{5}T\z/, @sroc_file.file_id
  end

  def test_file_id_does_not_end_with_t_for_retrospective_charges
    assert_match /\A\d{5}\z/, @retro_file.file_id
  end

  def test_filename_has_correct_format_for_sroc
    f = @sroc_file
    assert_equal "#{@regime.to_param}#{f.region}I#{f.file_id}.dat".downcase, f.filename
  end

  def test_filename_has_correct_format_for_retrospectives
    f = @retro_file
    assert_equal "#{@regime.to_param}#{f.region}I#{f.file_id}.dat".downcase, f.filename
  end
end
