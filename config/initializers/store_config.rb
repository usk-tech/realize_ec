# Store Configuration
# 環境変数 STORE_NAME でストアを切り替え

STORE_NAME = ENV.fetch('STORE_NAME', 'radika').to_sym

STORE_CONFIG = {
  radika: {
    name: 'ラディカ',
    name_en: 'Radika',
    color: '#FF6600',
    description: '本格インドカレーをご家庭で',
    description_en: 'Authentic Indian Curry for Your Home'
  },
  shrimpshells: {
    name: 'シュリンプシェルズ',
    name_en: 'ShrimpShells',
    color: '#0066FF',
    description: 'ハワイの味を冷凍でお届け',
    description_en: 'Hawaiian Flavors Delivered Frozen'
  },
  khukh_khuleg: {
    name: 'フフフレグ',
    name_en: 'Khukh Khuleg',
    color: '#00AA00',
    description: 'モンゴルの伝統料理',
    description_en: 'Traditional Mongolian Cuisine'
  }
}.freeze

# 現在のストア設定を取得
def current_store_config
  STORE_CONFIG[STORE_NAME]
end
