from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).parent
SOURCE = ROOT / "images" / "02 - Logo Horizontal.png"
OUTPUT = ROOT / "images" / "preview-whatsapp.png"
W, H = 1200, 630

canvas = Image.new("RGB", (W, H), "#0d0b08")

# Luz dourada discreta para manter a identidade da marca sem prejudicar a leitura.
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse((250, -260, 950, 440), fill=(185, 113, 18, 38))
glow = glow.filter(ImageFilter.GaussianBlur(95))
canvas = Image.alpha_composite(canvas.convert("RGBA"), glow)

logo = Image.open(SOURCE).convert("RGB")
logo.thumbnail((1060, 405), Image.Resampling.LANCZOS)
canvas.paste(logo, ((W - logo.width) // 2, 42))

draw = ImageDraw.Draw(canvas)
gold = "#d6a94f"
white = "#f8f4ea"
muted = "#b9ad99"
font_bold = ImageFont.truetype(r"C:/Windows/Fonts/arialbd.ttf", 32)
font_regular = ImageFont.truetype(r"C:/Windows/Fonts/arial.ttf", 23)

draw.rounded_rectangle((455, 466, 745, 472), radius=3, fill=gold)
headline = "CAMISAS DE TIME • POLOS • MULTIMARCAS"
box = draw.textbbox((0, 0), headline, font=font_bold)
draw.text(((W - (box[2] - box[0])) / 2, 500), headline, font=font_bold, fill=white)
subtitle = "Escolha seu tamanho e faça seu pedido pelo WhatsApp"
box = draw.textbbox((0, 0), subtitle, font=font_regular)
draw.text(((W - (box[2] - box[0])) / 2, 550), subtitle, font=font_regular, fill=muted)

canvas.convert("RGB").save(OUTPUT, "PNG", optimize=True)
