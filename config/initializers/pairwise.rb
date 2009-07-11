port = PRODUCTION ? '' : ''
PAIRWISE_PARAMS = {
  :development => {
    :host => "localhost:3000",
    :user => "",
    :pass => "",
    :protocol => "http",
  },
  :test => {
    :host => "localhost:3000",
    :user => "",
    :pass => "",
    :protocol => "http"
  },
  :production => {
    :host => "127.0.0.1:#{port}",
    :user => "",
    :pass => "",
    :protocol => "http"
  }
}[(ENV['RAILS_ENV'] || 'development').to_sym].merge(:key => '')