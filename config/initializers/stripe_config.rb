# Stripe Configuration
# ストア別に Stripe APIキーを切り替え

case ENV['STORE_NAME']&.to_sym
when :radika
  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', 'sk_test_radika_xxxxx')
when :shrimpshells
  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', 'sk_test_shrimpshells_xxxxx')
when :khukh_khuleg
  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', 'sk_test_khukh_khuleg_xxxxx')
else
  # デフォルトは radika
  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', 'sk_test_radika_xxxxx')
end

# Stripe Publishable Key も環境変数から取得
STRIPE_PUBLISHABLE_KEY = ENV.fetch('STRIPE_PUBLISHABLE_KEY', 'pk_test_radika_xxxxx')
