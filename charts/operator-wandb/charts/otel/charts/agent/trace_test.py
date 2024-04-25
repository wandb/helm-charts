# kubectl port-forward services/wandb-otel 4317:4317
# pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure the tracer to export traces to OTLP endpoint
otlp_exporter = OTLPSpanExporter(
    # This example assumes you're using gRPC. For HTTP, use OTLPSpanExporter as well.
    endpoint="localhost:4317",
    insecure=True  # Use False for secure (TLS) communication
)

# Set the tracer provider and associate it with the OTLP exporter
trace.set_tracer_provider(TracerProvider())
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(otlp_exporter))

# Create a tracer
tracer = trace.get_tracer(__name__)

# Start a span, this represents a single trace
with tracer.start_as_current_span("sample-trace"):
    # Simulate some processing...
    print("This is a sample trace sent to OTLP endpoint.")

# Note: In a real application, the script doesn't end immediately after a trace,
# allowing the exporter to send the trace. Ensure proper shutdown in production code.