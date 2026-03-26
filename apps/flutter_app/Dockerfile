FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
COPY apps/flutter_app/pubspec.yaml apps/flutter_app/pubspec.yaml
COPY apps/flutter_app/analysis_options.yaml apps/flutter_app/analysis_options.yaml
RUN cd apps/flutter_app && flutter pub get
COPY apps/flutter_app ./apps/flutter_app
RUN cd apps/flutter_app && flutter build web --release

FROM nginx:1.27-alpine AS runner
COPY infra/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/apps/flutter_app/build/web /usr/share/nginx/html
