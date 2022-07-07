module Api
  class ElectricityRatePlansController < ApplicationController
    def index
      # 受け取った「契約アンペア数」、「電気使用量」が不正な値でないか確認する
      user_electron_info = UserElectronInfo.new(user_electron_info_params)
      return render json: { status: 'ERROR', data: user_electron_info.errors } unless user_electron_info.save

      # 全てのプランの情報（電気料金等）を取得
      results = []

      ElectricityRatePlan.preload(:basic_charges, :usage_charges).find_each do |plan|
        # 電気料金を取得
        price = ElectricityRateCalculation.calculation_electricity_charge(plan, user_electron_info)
        next if price.blank?

        # プラン情報を格納
        results.push({ provider_name: plan.electric_power_provider.name,
                       plan_name: plan.name,
                       price: price })
      end

      render json: results
    end

    private

    def user_electron_info_params
      params.permit(:contract_amperage, :electricity_usage)
    end
  end
end