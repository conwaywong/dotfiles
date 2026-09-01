#!/usr/bin/env python3
"""Verify pinned release assets exist and match setup.sh SHA-256 values."""

import json
import re
import time
import urllib.error
import urllib.request
from pathlib import Path

SETUP = Path(__file__).parents[1] / "setup.sh"
TEXT = SETUP.read_text()


def variable(name: str) -> str:
    match = re.search(rf'^readonly {name}="([^"]+)"$', TEXT, re.MULTILINE)
    if not match:
        raise RuntimeError(f"Missing {name}")
    return match.group(1)


def expected(app: str, arch: str) -> str:
    match = re.search(
        rf'^  {re.escape(app)}:{re.escape(arch)}\) echo "([0-9a-f]{{64}})"',
        TEXT,
        re.MULTILINE,
    )
    if not match:
        raise RuntimeError(f"Missing checksum for {app}:{arch}")
    return match.group(1)


def release(repo: str, tag: str) -> dict:
    request = urllib.request.Request(
        f"https://api.github.com/repos/{repo}/releases/tags/{tag}",
        headers={"Accept": "application/vnd.github+json", "User-Agent": "dotfiles-ci"},
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.load(response)
        except (urllib.error.URLError, ConnectionError, TimeoutError):
            if attempt == 3:
                raise
            time.sleep(2**attempt)
    raise RuntimeError("unreachable")


def verify(repo: str, tag: str, app: str, assets: dict[str, str]) -> None:
    data = release(repo, tag)
    upstream = {asset["name"]: asset for asset in data["assets"]}
    for arch, name in assets.items():
        if name not in upstream:
            raise RuntimeError(f"{repo} {tag}: missing {name}")
        digest = upstream[name].get("digest")
        wanted = expected(app, arch)
        if digest and digest != f"sha256:{wanted}":
            raise RuntimeError(f"{name}: expected {wanted}, upstream reports {digest}")
        print(f"OK {repo} {tag} {name}")


neovim = variable("NEOVIM_VERSION")
fzf = variable("FZF_VERSION")
fonts = variable("NERD_FONTS_VERSION")
lazygit = variable("LAZYGIT_VERSION")
zoxide = variable("ZOXIDE_VERSION")
uv = variable("UV_VERSION")

verify("neovim/neovim", neovim, "neovim", {
    "x86_64": "nvim-linux-x86_64.tar.gz", "arm64": "nvim-linux-arm64.tar.gz"
})
verify("junegunn/fzf", fzf, "fzf", {
    "x86_64": f"fzf-{fzf.removeprefix('v')}-linux_amd64.tar.gz",
    "arm64": f"fzf-{fzf.removeprefix('v')}-linux_arm64.tar.gz",
})
verify("jesseduffield/lazygit", lazygit, "lazygit", {
    arch: f"lazygit_{lazygit.removeprefix('v')}_linux_{arch}.tar.gz"
    for arch in ("x86_64", "arm64")
})
verify("ajeetdsouza/zoxide", zoxide, "zoxide", {
    "x86_64": f"zoxide-{zoxide.removeprefix('v')}-x86_64-unknown-linux-musl.tar.gz",
    "arm64": f"zoxide-{zoxide.removeprefix('v')}-aarch64-unknown-linux-musl.tar.gz",
})
verify("astral-sh/uv", uv, "uv", {
    "x86_64": f"uv-x86_64-unknown-linux-gnu.tar.gz",
    "arm64": f"uv-aarch64-unknown-linux-gnu.tar.gz",
})
verify("ryanoasis/nerd-fonts", fonts, "nerd-fonts", {
    "*": "NerdFontsSymbolsOnly.zip"
})
