# Claude Office

Văn phòng pixel để chạy và theo dõi Claude Code, kèm terminal Claude Code thật và team trong mạng LAN.

Repo này chỉ chứa các bản phát hành. **Tải bản mới nhất ở [Releases](https://github.com/DinhVietKhoi/claud-office-app/releases/latest).**

| Máy | File |
|---|---|
| Mac chip Apple (M1 trở lên) | `Claude-Office-<version>-mac-arm64.zip` |
| Mac Intel | `Claude-Office-<version>-mac-x64.zip` |
| Windows | `Claude-Office-<version>-win-x64.zip` |
| Linux | `Claude-Office-<version>-linux-x64.tar.gz` |

Máy cần có sẵn Claude Code (lệnh `claude`). App đã gói kèm Node, không cần cài gì thêm.

- **macOS:** giải nén, kéo `Claude Office.app` vào Applications. Lần đầu mở bị chặn thì vào System Settings → Privacy & Security → Open Anyway.
- **Windows:** chuột phải file zip → Properties → Unblock, giải nén, nhấp đúp `Claude Office.vbs`.
- **Linux:** `tar -xzf Claude-Office-*-linux-x64.tar.gz -C ~/.local/opt` rồi chạy `~/.local/opt/claude-office/claude-office`.

Lần đầu mở app, bấm **Kết nối** để gắn hook vào Claude Code. Sau đó app tự báo khi có bản mới.
