import enum
import random
from opentelemetry.instrumentation.celery import CeleryInstrumentor
from io import BytesIO
from PIL import Image
from celery import Celery
from celery.signals import worker_process_init

from .storage import bucket


@worker_process_init.connect(weak=False)
def init_celery_tracing(*args, **kwargs):
    CeleryInstrumentor().instrument()

app = Celery(__name__, config_source="config.celery")

class Sizes(enum.IntEnum):
    Original = 10_000_000
    Big = 1024
    Medium = 512
    Small = 256
    Tiny = 128

    @property
    def segment(self) -> str:
        return self.name.lower()


def format_map(format: str) -> str:
    if format == "image/png":
        return "PNG"
    if format == "image/jpeg":
        return "JPEG"
    if format == "image/gif":
        return "GIF"
    raise Exception("unsupported image type")


@app.task
def resize_image(key: str, size: Sizes):
    size = Sizes(size)
    if size == Sizes.Original:
        return

    # Get the original image
    obj = bucket.Object(f"{Sizes.Original.segment}/{key}").get()
    bytes = obj["Body"].read()
    img = Image.open(BytesIO(bytes))
    # Resize it
    img.thumbnail((int(size), int(size)))

    # Save it
    buffer = BytesIO()
    img.save(buffer, format_map(obj["ContentType"]))
    buffer.seek(0)

    # Put it in the bucket
    new_key = f"{size.segment}/{key}"
    bucket.Object(new_key).put(Body=buffer, ContentType=obj["ContentType"])


__all__ = ["resize_image", "Sizes", "format_map"]
