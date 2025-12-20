---
weight: 1
title: "App Demo GIFs on Linux"
date: 2025-12-20
draft: false
author: Han
description: "App Demo GIFs on Linux"
tags: ["gif", "tips"]
categories: ["tips"]
---

# Creating High-Quality App Demo GIFs on Linux: The Professional Workflow

## Motivation

I recently built a TUI-based librarian app, namely **[Gorae](https://github.com/Han8931/gorae)**, for managing research papers, designed specifically for Vim and terminal lovers. I needed a polished demo for the README, but simple tools like **Peek** fell short—they lack the editing capabilities and text overlays needed for a professional presentation.

To do the project justice, I established a robust workflow on Arch Linux using **OBS Studio** for capture, **Kdenlive** for editing, and **Gifski** for high-fidelity compression.

## The Prerequisites

We need a few industry-standard tools. I've included installation commands for both Arch (my daily driver) and Ubuntu (for the majority of Linux users).

**On Arch Linux:**

```bash
sudo pacman -S obs-studio kdenlive ffmpeg gifski
```

**On Ubuntu / Debian:**

```bash
# Install core tools via apt
sudo apt update
sudo apt install obs-studio kdenlive ffmpeg

# Install gifski (best via Snap on Ubuntu)
sudo snap install gifski
```

* **OBS Studio:** For capturing raw, high-quality video footage.
* **Kdenlive:** For trimming the video and adding professional text overlays.
* **FFmpeg & Gifski:** The secret sauce for converting video to GIF without losing color quality.

## Step 1: Capture the Footage with OBS Studio

Don't rely on simple GIF screen recorders for the raw footage. They often drop frames. We want to record a high-quality video first and convert it later.

### Setting up the Source

1. Open OBS Studio.
2. Under the **Sources** panel, click the `+` button.
3. Choose your method:
* **Window Capture (Xcomposite/PipeWire):** Best if everything happens in one window.
* **Screen Capture (XSHM/PipeWire):** Essential if you use a tiling WM like i3 and plan to switch workspaces during the demo.



*Tip for i3/Tiling WM users:* If your recording looks cropped or off-center, right-click your Source in OBS and select **Transform > Fit to screen**.

*Ensure your source fits the canvas perfectly before recording.*

### Recording

Go to **Settings > Video** and ensure your Canvas Resolution matches your desired output (e.g., 1920x1080). Set your FPS to 30 or 60.

Hit **Start Recording**, perform your demo actions clearly and deliberately, and then hit **Stop Recording**. You will now have an `.mkv` or `.mp4` file in your Videos folder.

---

## Step 2: Editing and Polishing in Kdenlive

Now we move to Kdenlive to trim the fat and add context.

1. Launch Kdenlive.
2. Drag your recorded video file into the **Project Bin** (top left panel).
3. Drag the clip from the bin down onto the timeline on track **V1**.

### Trimming the Clip

Rarely is a raw recording perfect. You likely have awkward pauses at the start and end.

1. Move the playhead to the exact moment you want the demo to start.
2. Press `Shift + R` to cut the clip, or press `(` to instantly trim the beginning to the playhead's position.
3. Do the same for the end of the clip (press `)`).

> **Remove the Gap:** Trimming the start leaves empty space at 00:00. Right-click the empty area on the timeline and select **Remove Space** to snap your clip back to the beginning.

### Adding Description Text

To make your demo truly professional, add text overlays explaining what is happening (e.g., "Browse Files," "Compiling...").

1. In the Project Bin, click the **Add Clip** icon and select **Add Title Clip**.
2. In the editor window, type your text. Use a clean, bold font. Adding a slight shadow or background box helps readability against complex UIs.

*Designing clear, readable text for overlays.*

3. Drag your new Title Clip from the Project Bin onto timeline track **V2** (above your video).
4. Position it where the relevant action happens. You can grab the top corners of the title clip in the timeline to add smooth fade-ins and fade-outs.

*Layering text on V2 allows it to appear over your app demo.*

### Export the Video

Once edited, render the project back into a video file.

1. Press `Ctrl + Enter` (or click Render).
2. Choose **Generic > MP4-H264/AAC**.
3. Render the file (e.g., `final_edited_demo.mp4`).

---

## Step 3: The High-Quality GIF Conversion

This is the most important step. Most video editors, including Kdenlive, have poor built-in GIF exporters that result in grainy colors and huge file sizes.

We will use the command line to pipe the video data from FFmpeg directly into **Gifski**, a highly optimized GIF encoder that produces thousands of colors per frame instead of the usual 256.

Open your terminal in the folder holding your exported MP4 and run this command:

```bash
ffmpeg -i gorae_demo.mp4 -pix_fmt yuv420p -r 15 -f yuv4mpegpipe - | gifski -o gorae_final_demo.gif -
```

**The breakdown:**

* `-r 15`: Sets the output framerate to 15fps. This is usually the sweet spot for app demos—smooth enough to look good, but low enough to keep file size manageable for GitHub. Increase to 20 or 30 if needed.
* `gifski -o final_demo.gif -`: Takes the raw video pipe and generates a highly optimized GIF.

You now have a crisp, professional-looking GIF ready to be dropped into your project's README.md.
