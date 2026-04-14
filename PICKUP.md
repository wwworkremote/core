✦ Summary of Changes
   1. Replaced NewRelic with OpenTelemetry: Removed the newrelic_rpm gem and all associated configurations and binstubs.
   2. Configured OpenTelemetry: Added and configured the OpenTelemetry initializer to instrument Rails, Sidekiq, and other key components.
   3. Fixed Initialization Errors: Resolved a NameError by ensuring the RubyLLM initializer loads before models and by using fully qualified constant scoping.
   4. Updated Model Syntax: Migrated HackerNews::Item to the Rails 8 enum syntax, resolving an annotaterb error.
   5. Verified Environment: Rebuilt the Docker environment, ran migrations, and confirmed the app boots correctly inside the container.
   6. Added Regression Tests: Implemented model and request specs to ensure stable model and Avo resource loading.

  Plan for Restart
  Upon restart, you can pick up from these points:
   1. Verify OTLP Export: Ensure traces are being successfully sent to the Jaeger container (running at localhost:16686).
   2. Avo Integration: Confirm that the "AI / LLM" section in Avo is fully functional and that records can be managed.
   3. Ollama Connectivity: Test the connection to the new ollama service defined in docker-compose.yml via the ruby_llm initializer.
   4. Production Readiness: If deploying soon, ensure environment variables for OTLP endpoints are configured for the target environment.

  All changes have been committed and verified.
