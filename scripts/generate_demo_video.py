#!/usr/bin/env python3
import os
import sys
import math
import subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter

WIDTH = 1280
HEIGHT = 720
FPS = 30
DURATION = 13.5  # seconds
TOTAL_FRAMES = int(FPS * DURATION)

# Load fonts
FONT_REGULAR = "/System/Library/Fonts/HelveticaNeue.ttc"
FONT_MONO = "/System/Library/Fonts/Menlo.ttc"

font_title = ImageFont.truetype(FONT_REGULAR, 20)
font_bold = ImageFont.truetype(FONT_REGULAR, 22)
font_caption = ImageFont.truetype(FONT_REGULAR, 15)
font_mono = ImageFont.truetype(FONT_MONO, 13)
font_mono_small = ImageFont.truetype(FONT_MONO, 11)
font_badge = ImageFont.truetype(FONT_REGULAR, 11)
font_icon = ImageFont.truetype(FONT_REGULAR, 14)

# Easing functions
def ease_out_cubic(t):
    return 1 - math.pow(1 - t, 3)

def ease_in_out_quad(t):
    return 2 * t * t if t < 0.5 else 1 - math.pow(-2 * t + 2, 2) / 2

def ease_out_back(t):
    c1 = 1.70158
    c3 = c1 + 1
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)

def safe_box(xy):
    return [int(round(xy[0])), int(round(xy[1])), int(round(xy[2])), int(round(xy[3]))]

def safe_round_rect(draw, xy, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(safe_box(xy), radius=int(radius), fill=fill, outline=outline, width=int(width))

def safe_rect(draw, xy, fill=None, outline=None, width=1):
    draw.rectangle(safe_box(xy), fill=fill, outline=outline, width=int(width))

def safe_ellipse(draw, xy, fill=None, outline=None, width=1):
    draw.ellipse(safe_box(xy), fill=fill, outline=outline, width=int(width))

# Desktop background generator
def create_desktop_base():
    img = Image.new("RGBA", (WIDTH, HEIGHT), (14, 16, 24, 255))
    draw = ImageDraw.Draw(img)

    # Subtle radial aurora gradient in top-left and bottom-right
    for r in range(450, 0, -15):
        alpha = int(35 * (1 - r / 450))
        draw.ellipse([800 - r, 200 - r, 800 + r, 200 + r], fill=(45, 25, 95, alpha))
        draw.ellipse([300 - r, 500 - r, 300 + r, 500 + r], fill=(15, 65, 110, alpha))

    # macOS Top Menu Bar
    draw.rectangle([0, 0, WIDTH, 28], fill=(20, 22, 32, 220))
    draw.line([0, 28, WIDTH, 28], fill=(255, 255, 255, 25), width=1)
    
    # Apple icon & menu items
    draw.text((22, 5), "", font=font_title, fill=(240, 240, 245, 220))
    menus = ["File", "Edit", "View", "Window", "Help"]
    mx = 55
    for m in menus:
        draw.text((mx, 6), m, font=font_badge, fill=(200, 205, 220, 200))
        mx += 45

    # Right status items: Osoko Camera Icon, Control Center, Time
    # Osoko tiny camera icon
    draw.text((WIDTH - 150, 6), "📷", font=font_badge, fill=(0, 210, 255, 230))
    draw.text((WIDTH - 120, 6), "Wi-Fi", font=font_badge, fill=(180, 185, 200, 180))
    draw.text((WIDTH - 70, 6), "9:41 AM", font=font_badge, fill=(240, 240, 245, 220))

    return img

desktop_base = create_desktop_base()

# Draw a sleek code editor window
def draw_code_window(target, x, y, w, h):
    draw = ImageDraw.Draw(target)
    # Window shadow
    shadow_box = [x - 8, y - 4, x + w + 8, y + h + 16]
    safe_round_rect(draw, shadow_box, radius=16, fill=(0, 0, 0, 80))
    
    # Window frame
    safe_round_rect(draw, [x, y, x + w, y + h], radius=12, fill=(22, 25, 36, 245), outline=(255, 255, 255, 35), width=1)
    
    # Title bar
    safe_round_rect(draw, [x, y, x + w, y + 36], radius=12, fill=(28, 32, 46, 255))
    safe_rect(draw, [x, y + 26, x + w, y + 36], fill=(28, 32, 46, 255))
    draw.line([x, y + 36, x + w, y + 36], fill=(255, 255, 255, 20), width=1)
    
    # Traffic lights
    safe_ellipse(draw, [x + 14, y + 13, x + 24, y + 23], fill=(255, 95, 87, 255))
    safe_ellipse(draw, [x + 32, y + 13, x + 42, y + 23], fill=(254, 188, 46, 255))
    safe_ellipse(draw, [x + 50, y + 13, x + 60, y + 23], fill=(40, 200, 64, 255))
    draw.text((x + w // 2 - 60, y + 10), "TextRecognitionService.swift", font=font_badge, fill=(160, 165, 185, 200))
    
    # Code lines
    lines = [
        ("import", (255, 120, 180), " Vision", (240, 240, 245)),
        ("import", (255, 120, 180), " CoreGraphics", (240, 240, 245)),
        ("", (0, 0, 0), "", (0, 0, 0)),
        ("public enum", (255, 120, 180), " TextRecognitionService {", (240, 240, 245)),
        ("    /// Blazingly fast native Apple Vision OCR", (110, 120, 145), "", (0, 0, 0)),
        ("    public static func", (255, 120, 180), " copyText(from url: URL) async -> String {", (240, 240, 245)),
        ("        let req = VNRecognizeTextRequest()", (130, 215, 250), "", (0, 0, 0)),
        ("        req.recognitionLevel = ", (240, 240, 245), ".accurate", (255, 205, 100)),
        ("        req.usesLanguageCorrection = ", (240, 240, 245), "false  // 175x speedup!", (100, 230, 160)),
        ("        return try! await req.perform()", (240, 240, 245), "", (0, 0, 0)),
        ("    }", (240, 240, 245), "", (0, 0, 0)),
        ("}", (240, 240, 245), "", (0, 0, 0)),
    ]
    
    cy = y + 50
    for idx, (kw, kw_color, rest, rest_color) in enumerate(lines):
        line_num = f"{idx+1:>2} "
        draw.text((x + 18, cy), line_num, font=font_mono, fill=(90, 95, 115, 180))
        if kw:
            draw.text((x + 50, cy), kw, font=font_mono, fill=kw_color)
            draw.text((x + 50 + len(kw) * 8, cy), rest, font=font_mono, fill=rest_color)
        else:
            draw.text((x + 50, cy), rest, font=font_mono, fill=rest_color)
        cy += 20

# Draw target chat/drop app window on the left
def draw_drop_target_window(target, x, y, w, h, is_hovered=False):
    draw = ImageDraw.Draw(target)
    # Shadow
    safe_round_rect(draw, [x - 6, y - 3, x + w + 6, y + h + 12], radius=14, fill=(0, 0, 0, 70))
    # Frame
    border_col = (0, 210, 255, 180) if is_hovered else (255, 255, 255, 30)
    safe_round_rect(draw, [x, y, x + w, y + h], radius=12, fill=(18, 20, 28, 240), outline=border_col, width=2 if is_hovered else 1)
    # Title bar
    safe_round_rect(draw, [x, y, x + w, y + 32], radius=12, fill=(24, 27, 38, 255))
    safe_rect(draw, [x, y + 22, x + w, y + 32], fill=(24, 27, 38, 255))
    safe_ellipse(draw, [x + 12, y + 11, x + 20, y + 19], fill=(255, 95, 87, 255))
    safe_ellipse(draw, [x + 28, y + 11, x + 36, y + 19], fill=(254, 188, 46, 255))
    safe_ellipse(draw, [x + 44, y + 11, x + 52, y + 19], fill=(40, 200, 64, 255))
    draw.text((x + w // 2 - 40, y + 9), "Slack / Chat", font=font_badge, fill=(170, 175, 195, 200))
    
    # Message bubbles
    safe_round_rect(draw, [x + 16, y + 48, x + 220, y + 80], radius=8, fill=(35, 40, 56, 200))
    draw.text((x + 26, y + 56), "Can you send the OCR snippet?", font=font_badge, fill=(220, 225, 240, 230))
    
    # Drop zone at bottom
    dz_outline = (0, 210, 255, 200) if is_hovered else (70, 75, 95, 120)
    dz_fill = (0, 210, 255, 25) if is_hovered else (26, 30, 42, 160)
    safe_round_rect(draw, [x + 16, y + h - 55, x + w - 16, y + h - 14], radius=8, fill=dz_fill, outline=dz_outline, width=1)
    prompt_text = "✨ Drop screenshot here to send" if is_hovered else "Drop files here to upload..."
    prompt_col = (0, 230, 255, 255) if is_hovered else (120, 125, 145, 180)
    draw.text((x + 30, y + h - 42), prompt_text, font=font_badge, fill=prompt_col)

# Draw an Osoko floating screenshot card
def draw_osoko_card(target, cx, cy, card_w, card_h, title="Screenshot", snippet_text=None, is_hover=False, show_ocr_toast=False, show_share_menu=False):
    draw = ImageDraw.Draw(target)
    
    # Outer specular shadow
    safe_round_rect(draw, [cx - 8, cy - 4, cx + card_w + 8, cy + card_h + 16], radius=16, fill=(0, 0, 0, 110))
    
    # Glassmorphic card body
    safe_round_rect(draw, [cx, cy, cx + card_w, cy + card_h], radius=12, fill=(28, 32, 46, 235), outline=(255, 255, 255, 60 if is_hover else 35), width=1)
    
    # Inner screenshot preview simulation
    inner_box = [cx + 8, cy + 8, cx + card_w - 8, cy + card_h - 26]
    safe_round_rect(draw, inner_box, radius=8, fill=(16, 18, 26, 255))
    
    # Simulated thumbnail content
    safe_rect(draw, [cx + 12, cy + 14, cx + card_w - 12, cy + 28], fill=(32, 38, 54, 255))
    draw.text((int(cx + 16), int(cy + 16)), "⌘ ⇧ 4 Capture Snippet", font=font_mono_small, fill=(0, 210, 255, 230))
    draw.text((int(cx + 16), int(cy + 34)), "copyText(from url: URL)", font=font_mono_small, fill=(255, 205, 100, 230))
    draw.text((int(cx + 16), int(cy + 50)), "usesLanguageCorrection = false", font=font_mono_small, fill=(100, 230, 160, 230))
    draw.text((int(cx + 16), int(cy + 66)), "return try! await req.perform()", font=font_mono_small, fill=(200, 205, 220, 200))
    
    # Dimensions badge
    badge_x = cx + card_w - 74
    badge_y = cy + card_h - 22
    safe_round_rect(draw, [badge_x, badge_y, cx + card_w - 8, cy + card_h - 7], radius=4, fill=(10, 12, 18, 180))
    draw.text((int(badge_x + 6), int(badge_y + 1)), "1280 × 720", font=font_mono_small, fill=(160, 165, 180, 200))

    # Top dismiss and pin buttons
    if is_hover:
        # Close '✕' on left
        safe_ellipse(draw, [cx + 12, cy + 12, cx + 26, cy + 26], fill=(0, 0, 0, 160), outline=(255, 255, 255, 40), width=1)
        draw.text((int(cx + 16), int(cy + 12)), "✕", font=font_badge, fill=(220, 220, 230, 220))
        # Pin '📌' on right
        safe_ellipse(draw, [cx + card_w - 26, cy + 12, cx + card_w - 12, cy + 26], fill=(0, 0, 0, 160), outline=(255, 255, 255, 40), width=1)
        draw.text((int(cx + card_w - 23), int(cy + 13)), "📌", font=font_badge, fill=(255, 220, 100, 220))
        
        # Bottom hover action pill
        pill_w = 140
        pill_h = 28
        pill_x = cx + (card_w - pill_w) // 2
        pill_y = cy + card_h + 6
        safe_round_rect(draw, [pill_x, pill_y, pill_x + pill_w, pill_y + pill_h], radius=14, fill=(20, 23, 34, 245), outline=(255, 255, 255, 50), width=1)
        
        # Action icons: OCR [⚡], Share [↗], Save [💾]
        if show_ocr_toast:
            safe_round_rect(draw, [pill_x + 8, pill_y + 3, pill_x + 44, pill_y + 25], radius=6, fill=(0, 210, 255, 60))
        draw.text((int(pill_x + 14), int(pill_y + 6)), "⚡ OCR", font=font_badge, fill=(0, 230, 255, 255))
        
        if show_share_menu:
            safe_round_rect(draw, [pill_x + 52, pill_y + 3, pill_x + 94, pill_y + 25], radius=6, fill=(120, 90, 240, 60))
        draw.text((int(pill_x + 58), int(pill_y + 6)), "↗ Share", font=font_badge, fill=(200, 205, 230, 230))
        draw.text((int(pill_x + 104), int(pill_y + 6)), "💾", font=font_badge, fill=(180, 185, 205, 200))

    # Toast message: Text Copied ✓
    if show_ocr_toast:
        tw = 120
        th = 26
        tx = cx + (card_w - tw) // 2
        ty = cy - 32
        safe_round_rect(draw, [tx - 4, ty - 2, tx + tw + 4, ty + th + 4], radius=14, fill=(0, 0, 0, 80))
        safe_round_rect(draw, [tx, ty, tx + tw, ty + th], radius=13, fill=(15, 22, 35, 245), outline=(0, 210, 255, 160), width=1)
        draw.text((int(tx + 14), int(ty + 5)), "Text Copied ✓", font=font_badge, fill=(0, 230, 255, 255))

    # Native macOS Share popover menu
    if show_share_menu:
        sm_w = 140
        sm_h = 110
        sm_x = cx + card_w - sm_w
        sm_y = cy + card_h + 38
        safe_round_rect(draw, [sm_x - 6, sm_y - 2, sm_x + sm_w + 6, sm_y + sm_h + 8], radius=12, fill=(0, 0, 0, 90))
        safe_round_rect(draw, [sm_x, sm_y, sm_x + sm_w, sm_y + sm_h], radius=10, fill=(26, 30, 44, 250), outline=(255, 255, 255, 45), width=1)
        share_items = [("AirDrop", "📡"), ("Messages", "💬"), ("Mail", "✉️"), ("Notes", "📝")]
        sy = sm_y + 8
        for name, icon in share_items:
            draw.text((int(sm_x + 12), int(sy)), icon, font=font_badge, fill=(200, 205, 220, 220))
            draw.text((int(sm_x + 36), int(sy)), name, font=font_badge, fill=(220, 225, 240, 230))
            sy += 24

# Draw smooth animated mouse cursor
def draw_cursor(target, x, y, is_snip=False, is_dragging=False):
    draw = ImageDraw.Draw(target)
    x = int(round(x))
    y = int(round(y))
    if is_snip:
        # Crosshairs cursor
        r = 10
        safe_ellipse(draw, [x - r, y - r, x + r, y + r], outline=(255, 255, 255, 220), width=1)
        draw.line([x - r - 4, y, x + r + 4, y], fill=(255, 255, 255, 220), width=1)
        draw.line([x, y - r - 4, x, y + r + 4], fill=(255, 255, 255, 220), width=1)
    else:
        # Sleek macOS pointer arrow
        pts = [(x, y), (x + 14, y + 14), (x + 7, y + 15), (x + 11, y + 23), (x + 7, y + 25), (x + 3, y + 17), (x, y + 20)]
        draw.polygon(pts, fill=(255, 255, 255, 255), outline=(0, 0, 0, 200))

# Draw feature caption pill at bottom center
def draw_caption(target, title, subtitle):
    draw = ImageDraw.Draw(target)
    pill_w = 460
    pill_h = 44
    px = (WIDTH - pill_w) // 2
    py = HEIGHT - 68
    safe_round_rect(draw, [px - 6, py - 3, px + pill_w + 6, py + pill_h + 8], radius=24, fill=(0, 0, 0, 90))
    safe_round_rect(draw, [px, py, px + pill_w, py + pill_h], radius=22, fill=(18, 22, 34, 240), outline=(255, 255, 255, 45), width=1)
    
    # Blue accent dot
    safe_ellipse(draw, [px + 18, py + 18, px + 26, py + 26], fill=(0, 210, 255, 255))
    draw.text((px + 36, py + 8), title, font=font_caption, fill=(255, 255, 255, 255))
    draw.text((px + 36, py + 24), subtitle, font=font_badge, fill=(160, 170, 195, 220))


def render_frame(frame_idx):
    t = frame_idx / float(FPS)
    frame = desktop_base.copy()
    draw = ImageDraw.Draw(frame)

    # Static windows on desktop
    draw_drop_target_window(frame, 60, 120, 290, 440, is_hovered=(8.8 <= t <= 10.8))
    draw_code_window(frame, 380, 80, 520, 360)

    # Base coordinates for Osoko corner stack
    stack_x = WIDTH - 240
    stack_y1 = HEIGHT - 200
    stack_y2 = HEIGHT - 370

    # ========================================================
    # PHASE 1 (0.0s - 2.6s): Snip Selection (⌘⇧4) & Shutter Flash
    # ========================================================
    if t < 2.6:
        caption_title = "⌘ ⇧ 4  Native Crosshair Snippet"
        caption_sub = "Overridden to route captures into Osoko with zero lag"
        
        # Selection animation
        p = t / 2.6
        if p < 0.2:
            # Cursor enters
            cx = 400 + 400 * ease_out_cubic(p / 0.2)
            cy = 150
            draw_cursor(frame, cx, cy, is_snip=True)
        elif p < 0.75:
            # Drag selection rectangle over code window
            sp = (p - 0.2) / 0.55
            sel_x = 420
            sel_y = 120
            sel_w = 420 * ease_out_cubic(sp)
            sel_h = 240 * ease_out_cubic(sp)
            # Semi-transparent selection fill & border
            safe_rect(draw, [sel_x, sel_y, sel_x + sel_w, sel_y + sel_h], fill=(0, 180, 255, 35), outline=(0, 210, 255, 220), width=1)
            # Dimensions tag
            draw.text((sel_x + sel_w + 5, sel_y + sel_h - 10), f"{int(sel_w*3)} × {int(sel_h*3)}", font=font_mono_small, fill=(0, 230, 255, 255))
            draw_cursor(frame, sel_x + sel_w, sel_y + sel_h, is_snip=True)
        else:
            # Shutter flash
            flash_p = (p - 0.75) / 0.25
            if flash_p < 0.4:
                flash_alpha = int(90 * (1 - flash_p / 0.4))
                flash_layer = Image.new("RGBA", (WIDTH, HEIGHT), (255, 255, 255, flash_alpha))
                frame = Image.alpha_composite(frame, flash_layer)
                draw = ImageDraw.Draw(frame)
            draw_cursor(frame, 840, 360, is_snip=False)

    # ========================================================
    # PHASE 2 (2.6s - 5.5s): Slide Into Floating Specular Stack
    # ========================================================
    elif t < 5.5:
        caption_title = "Floating Specular Shelf"
        caption_sub = "Transient corner cards keep your desktop 100% clean"
        p = (t - 2.6) / 2.9
        
        # First card slides in from right
        card1_slide = ease_out_back(min(1.0, p * 2.0))
        cur_x1 = WIDTH + 50 - (WIDTH + 50 - stack_x) * card1_slide
        draw_osoko_card(frame, cur_x1, stack_y1, 210, 140, is_hover=False)

        # Second card (Window snip) drops into stack at p > 0.45
        if p > 0.45:
            p2 = min(1.0, (p - 0.45) / 0.55)
            card2_slide = ease_out_back(p2)
            cur_x2 = WIDTH + 50 - (WIDTH + 50 - stack_x) * card2_slide
            draw_osoko_card(frame, cur_x2, stack_y2, 210, 140, is_hover=False)

        # Cursor moves toward stack
        cmx = 840 + (stack_x + 100 - 840) * ease_out_cubic(p)
        cmy = 360 + (stack_y1 + 70 - 360) * ease_out_cubic(p)
        draw_cursor(frame, cmx, cmy, is_snip=False)

    # ========================================================
    # PHASE 3 (5.5s - 8.5s): Vision OCR & Native Share Menu
    # ========================================================
    elif t < 8.5:
        p = (t - 5.5) / 3.0
        # Draw background stack card
        draw_osoko_card(frame, stack_x, stack_y2, 210, 140, is_hover=False)

        if p < 0.5:
            caption_title = "⚡ Instant Vision OCR (0.13s)"
            caption_sub = "Extract text, code, or URLs with 1-click clipboard copy"
            # Click OCR button
            ocr_toast = p > 0.15
            draw_osoko_card(frame, stack_x, stack_y1, 210, 140, is_hover=True, show_ocr_toast=ocr_toast, show_share_menu=False)
            draw_cursor(frame, stack_x + 55, stack_y1 + 155, is_snip=False)
        else:
            caption_title = "↗ Native macOS Share Sheet"
            caption_sub = "AirDrop, Messages, Notes, Reminders directly from the card"
            draw_osoko_card(frame, stack_x, stack_y1, 210, 140, is_hover=True, show_ocr_toast=False, show_share_menu=True)
            draw_cursor(frame, stack_x + 95, stack_y1 + 155, is_snip=False)

    # ========================================================
    # PHASE 4 (8.5s - 11.2s): Drag & Drop Straight Into Apps
    # ========================================================
    elif t < 11.2:
        caption_title = "Drag & Drop Straight into Any App"
        caption_sub = "Slack, Figma, ChatGPT, Finder — with 15-minute deferred cleanup"
        p = (t - 8.5) / 2.7

        # Top card remains in stack
        draw_osoko_card(frame, stack_x, stack_y2, 210, 140, is_hover=False)

        # Bottom card is dragged toward chat window (from stack_x, stack_y1 to 100, 380)
        drag_p = ease_in_out_quad(min(1.0, p / 0.8))
        drag_x = stack_x + (100 - stack_x) * drag_p
        drag_y = stack_y1 + (380 - stack_y1) * drag_p

        if p < 0.8:
            # Lift shadow & slight tilt
            draw_osoko_card(frame, drag_x, drag_y, 200, 135, is_hover=False)
            draw_cursor(frame, drag_x + 90, drag_y + 60, is_snip=False)
        else:
            # Dropped into chat
            draw_osoko_card(frame, 100, 380, 190, 125, is_hover=False)
            draw_cursor(frame, 200, 440, is_snip=False)

    # ========================================================
    # PHASE 5 (11.2s - 13.5s): Auto-Collapse & Bottom-Edge Reveal
    # ========================================================
    else:
        p = (t - 11.2) / 2.3
        
        if p < 0.45:
            caption_title = "10s Inactivity Auto-Collapse"
            caption_sub = "Slides off-screen so your workspace stays completely clear"
            collapse_p = ease_in_out_quad(p / 0.45)
            offset = collapse_p * 220
            draw_osoko_card(frame, stack_x + offset, stack_y2, 210, 140, is_hover=False)
            draw_cursor(frame, 700, 500, is_snip=False)
        else:
            caption_title = "Edge Reveal"
            caption_sub = "Bump cursor to bottom-right edge to slide cards back out"
            reveal_p = (p - 0.45) / 0.55
            # Cursor moves down to bottom right edge
            cx = 700 + (WIDTH - 40 - 700) * ease_out_cubic(reveal_p)
            cy = 500 + (HEIGHT - 10 - 500) * ease_out_cubic(reveal_p)
            draw_cursor(frame, cx, cy, is_snip=False)
            # Card slides back out
            slide_out = ease_out_back(min(1.0, reveal_p * 1.5))
            cur_x = (WIDTH - 20) - (220) * slide_out
            draw_osoko_card(frame, cur_x, stack_y2, 210, 140, is_hover=False)

    # Always draw bottom caption
    draw_caption(frame, caption_title, caption_sub)

    return frame.convert("RGB")

def main():
    print(f"==> Rendering {TOTAL_FRAMES} frames ({DURATION}s @ {FPS}fps)...")
    out_mp4 = "assets/demo.mp4"
    out_gif = "assets/demo.gif"
    
    # 1. Pipe raw RGB frames to ffmpeg to create mp4
    ffmpeg_cmd = [
        "ffmpeg", "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{WIDTH}x{HEIGHT}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-preset", "fast",
        "-crf", "18",
        out_mp4
    ]
    
    proc = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE)
    
    for i in range(TOTAL_FRAMES):
        if i % 30 == 0:
            print(f"  Frame {i}/{TOTAL_FRAMES} ({(i/TOTAL_FRAMES)*100:.1f}%)")
        frame = render_frame(i)
        proc.stdin.write(frame.tobytes())
        
    proc.stdin.close()
    proc.wait()
    print(f"==> Generated MP4: {out_mp4} ({os.path.getsize(out_mp4) / 1024:.1f} KB)")
    
    # 2. Generate high-quality optimized GIF with palettegen & paletteuse
    print("==> Generating high-quality GIF with ffmpeg palette...")
    gif_cmd = [
        "ffmpeg", "-y",
        "-i", out_mp4,
        "-vf", "fps=20,scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128:reserve_transparent=0[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3",
        out_gif
    ]
    subprocess.run(gif_cmd, check=True)
    print(f"==> Generated GIF: {out_gif} ({os.path.getsize(out_gif) / (1024 * 1024):.2f} MB)")

if __name__ == "__main__":
    main()
