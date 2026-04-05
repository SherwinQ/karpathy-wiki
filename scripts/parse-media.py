#!/usr/bin/env python3
"""
PDF / 图片解析脚本 — 将 PDF 或图片转换为 Markdown

基于百度 PaddleOCR 的 Layout Parsing API，支持：
- PDF 文档解析（文字、表格、图表提取）
- 图片 OCR（文字识别、图表理解）
- 自动提取文档中的图片并保存

依赖：pip install requests
配置：在 wiki 根目录创建 .env 文件，或设置环境变量

    LAYOUT_API_URL=https://your-api-url
    LAYOUT_API_TOKEN=your-token

用法：
    python3 parse-media.py <文件路径> [--output-dir <输出目录>]

示例：
    python3 parse-media.py paper.pdf
    python3 parse-media.py paper.pdf --output-dir wiki/raw
    python3 parse-media.py diagram.png
"""

import argparse
import base64
import os
import sys
from pathlib import Path

try:
    import requests
except ImportError:
    print("ERROR: 需要安装 requests 库：pip install requests", file=sys.stderr)
    sys.exit(2)


def load_config(wiki_root: Path) -> tuple[str, str]:
    """从环境变量或 .env 文件加载 API 配置。"""

    api_url = os.environ.get("LAYOUT_API_URL", "")
    api_token = os.environ.get("LAYOUT_API_TOKEN", "")

    # 尝试从 wiki 根目录的 .env 读取
    env_file = wiki_root / ".env"
    if env_file.is_file():
        for line in env_file.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key == "LAYOUT_API_URL":
                api_url = value
            elif key == "LAYOUT_API_TOKEN":
                api_token = value

    if not api_url or not api_token:
        print(
            "ERROR: 未配置 API。\n"
            "请在 wiki 根目录的 .env 文件中设置：\n"
            "  LAYOUT_API_URL=https://your-api-url\n"
            "  LAYOUT_API_TOKEN=your-token\n"
            "或设置环境变量。",
            file=sys.stderr,
        )
        sys.exit(2)

    return api_url, api_token


def parse_file(file_path: Path, output_dir: Path, api_url: str, api_token: str) -> list[Path]:
    """调用 API 解析文件，返回生成的 Markdown 文件路径列表。"""

    suffix = file_path.suffix.lower()
    if suffix == ".pdf":
        file_type = 0
    elif suffix in (".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff"):
        file_type = 1
    else:
        print(f"ERROR: 不支持的文件格式 {suffix}（仅支持 PDF 和图片）", file=sys.stderr)
        sys.exit(2)

    with open(file_path, "rb") as f:
        file_bytes = f.read()
    file_data = base64.b64encode(file_bytes).decode("ascii")

    headers = {
        "Authorization": f"token {api_token}",
        "Content-Type": "application/json",
    }

    payload = {
        "file": file_data,
        "fileType": file_type,
        "useDocOrientationClassify": False,
        "useDocUnwarping": False,
        "useChartRecognition": False,
    }

    print(f"正在解析: {file_path.name} ...")
    response = requests.post(api_url, json=payload, headers=headers, timeout=120)

    if response.status_code != 200:
        print(f"ERROR: API 请求失败 (HTTP {response.status_code})", file=sys.stderr)
        print(response.text[:500], file=sys.stderr)
        sys.exit(2)

    result = response.json()["result"]
    output_dir.mkdir(parents=True, exist_ok=True)
    generated_files: list[Path] = []

    for i, res in enumerate(result.get("layoutParsingResults", [])):
        md_filename = output_dir / f"doc_{i}.md"
        md_content = res["markdown"]["text"]
        md_filename.write_text(md_content, encoding="utf-8")
        generated_files.append(md_filename)
        print(f"  Markdown: {md_filename}")

        # 保存解析出的图片
        for img_path, img_url in res["markdown"].get("images", {}).items():
            full_img_path = output_dir / img_path
            full_img_path.parent.mkdir(parents=True, exist_ok=True)
            try:
                img_bytes = requests.get(img_url, timeout=30).content
                full_img_path.write_bytes(img_bytes)
                print(f"  Image: {full_img_path}")
            except Exception as exc:
                print(f"  WARNING: 图片下载失败 {img_path}: {exc}", file=sys.stderr)

        # 保存解析后的输出图片
        for img_name, img_url in res.get("outputImages", {}).items():
            try:
                img_resp = requests.get(img_url, timeout=30)
                if img_resp.status_code == 200:
                    filename = output_dir / f"{img_name}_{i}.jpg"
                    filename.write_bytes(img_resp.content)
                    print(f"  Output: {filename}")
            except Exception as exc:
                print(f"  WARNING: 输出图片下载失败 {img_name}: {exc}", file=sys.stderr)

    return generated_files


def main():
    parser = argparse.ArgumentParser(description="PDF/图片 → Markdown 解析工具")
    parser.add_argument("file", help="PDF 或图片文件路径")
    parser.add_argument(
        "--output-dir",
        default=None,
        help="输出目录（默认：<文件所在目录>_parsed）",
    )
    args = parser.parse_args()

    file_path = Path(args.file).resolve()
    if not file_path.is_file():
        print(f"ERROR: 文件不存在: {file_path}", file=sys.stderr)
        sys.exit(2)

    # 向上查找 wiki 根目录（包含 log.md 或 raw/ 的目录）
    wiki_root = file_path.parent
    for ancestor in file_path.parents:
        if (ancestor / "log.md").is_file() or (ancestor / "raw").is_dir():
            wiki_root = ancestor
            break

    api_url, api_token = load_config(wiki_root)

    if args.output_dir:
        output_dir = Path(args.output_dir).resolve()
    else:
        stem = file_path.stem
        output_dir = file_path.parent / f"{stem}_parsed"

    generated = parse_file(file_path, output_dir, api_url, api_token)

    if generated:
        print(f"\n完成！生成 {len(generated)} 个 Markdown 文件。")
        for f in generated:
            print(f"  {f}")


if __name__ == "__main__":
    main()
