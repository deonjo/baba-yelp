# Cross-origin requests only matter for browser clients (e.g. the Flutter web
# build during development); the iOS and Android apps are not subject to CORS.
# Set CORS_ORIGINS to a comma-separated list of allowed origins in production.
allowed_origins = ENV.fetch("CORS_ORIGINS") { Rails.env.production? ? "" : "*" }
  .split(",").map(&:strip).compact_blank

if allowed_origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*allowed_origins)
      resource "/api/*", headers: :any, methods: %i[get post put patch delete options head]
    end
  end
end
