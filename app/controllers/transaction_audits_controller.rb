# frozen_string_literal: true

class TransactionAuditsController < ApplicationController
  include RegimeScope
  before_action :set_transaction, only: [:show]

  def show
    @logs = build_logs
  end

  private
    def set_transaction
      set_regime
      @transaction = Query::FindTransaction.call(regime: @regime,
                                                 transaction_id: params[:id])
    end

    def build_logs
      Enumerator.new do |y|
        @transaction.audit_logs.order(:created_at, :id).each do |l|
          action = l.action
          created = l.created_at
          who = l.user.full_name

          mods = l.payload.fetch("modifications", {})
          mods.each do |k, v|
            d = ViewModels::AuditDetail.new
            d.action = action
            d.when = created
            d.who = who
            d.attribute = k
            d.old_value = v[0]
            d.new_value = v[1]
            y << d
          end 
        end
      end
    end
end
