We had to create a seperate chart, because the offical one does not support

1. We need to send an otlphttp to the console server. The name of this service
   is dynamic. TEL helm chart does not support dynamic pipeline values
2. We could do the above as a config map, and pass it into the agent... however,
   otel helm does not support using custom config maps names because they need
   to be based on the release name.
