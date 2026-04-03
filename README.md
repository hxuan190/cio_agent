# 🚀 Minimalist Core Agent System (for Claude Code)

Welcome to the **Minimalist Core Agent System** — một bộ khung framework cực kì thanh thoát, được thiết kế chuyên biệt để tiết kiệm tối đa API Tokens và đẩy hệ thống AI Agents của bạn chạm tới giới hạn cực đại của sự thông minh.

## 🌟 Tại sao lại có hệ thống này?
Hệ thống này được phân nhánh (fork) về và cắt bỏ toàn bộ 95% sự nặng nề của mã nguồn `everything-claude-code` gốc (các IDE thừa thãi, files thử nghiệm). Nó chỉ giữ lại duy nhất thư mục Lõi (`/core`) và cấu hình CLI nguyên thủy, được tinh chỉnh theo chiến thuật **Macro-Architect & Micro-Agents** với phương châm cốt lõi: **Không bao giờ lãng phí một token nào cho dữ liệu rác!**

## 📦 Cấu trúc Bức Tranh Tổng Thể
```text
/
├── .claude/            # Cấu hình gốc CLI mặc định của Claude Code đang vận hành
├── core/               # LÕI HỆ THỐNG - Nơi chứa trí thông minh thực sự và Rule AI
│   ├── agents/         # Sub-agents chuyên trách (Ví dụ: router.md - Kẻ điều phối)
│   ├── hooks/          # Tự động hóa sự kiện ngầm bảo vệ hệ thống trước và sau khi AI chạy
│   ├── mcp-configs/    # Cấu hình kết nối siêu máy chủ: Github, Browser, DB, Search...
│   ├── rules/          # Luật thép gò ép AI thao tác Code & tiết kiệm bộ nhớ (Token Economy)
│   ├── scripts/        # Lớp vỏ lọc (Wrapper/Hooks code) giảm lỗi tràn thông tin Terminal
│   └── skills/         # Kho bí kíp tinh hoa (State Checkpoint, Bảo Mật, Quy trình Code chuẩn)
└── README.md
```

---

## 🛠 Hướng dẫn Cài Đặt (Installation) trong 3 bước

**1. Định vị Trái Tim Hệ Thống (Plugin Root):**
Để toàn bộ các kịch bản Hook đằng sau làm việc chính xác, hãy thêm biến môi trường trỏ thẳng vào thư mục `core` của repo này trong file `~/.bashrc` hoặc `~/.zshrc`:
```bash
# Sửa đường dẫn thực tế trỏ tới repo của bạn:
export CLAUDE_PLUGIN_ROOT="/home/your_username/projects/ab/everything-claude-code/core"
```
Đừng quên load lại terminal (`source ~/.bashrc`).

**2. Tiêm Cấu hình Tự động (Hooks):**
Gắn các chốt chặn an toàn (cảnh báo AI, gom logs, dọn dẹp bộ nhớ) bằng cách copy mảng `"hooks"` từ file `core/hooks/hooks.json` và dán vào file cấu hình `~/.claude/settings.json` trong máy tính của bạn.

**3. Khai mở Tri Giác (MCP Servers):**
Copy bộ config sẵn có trong `core/mcp-configs/mcp-servers.json` và bổ sung vào khu vực `"mcpServers"` bên trong file `~/.claude.json`. (Bạn tự thay thế các YOUR_KEY thành API Key thật). Khởi động lại AI CLI là xong!

---

## 🧠 Sổ tay Rèn luyện Tuyệt Phẩm (How to Use)

Thay vì phó mặc ra lệnh cho AI quét lung tung tiêu tốn hàng vạn tokens, hãy vận hành theo 4 cột trụ (Pillars) sau:

### 1. Gọi Kẻ Điều Phối (Master Router Agent)
Không tự ý ra lệnh code thẳng nếu là task tính năng mới lớn. Hãy ủy quyền cho Bộ Não Router:
- **Câu lệnh:** `@core/agents/router.md Tôi muốn xây dựng hệ thống thanh toán với Stripe.`
- **Kết quả:** Router không code, nó sẽ rã requirement của bạn ra nhỏ giọt, tạo ra các checklist và vạch định Sub-Agents tương ứng như Coder, Planner xử lý từng bước cục bộ.

### 2. Thuật nén Trí Nhớ (State Checkout Handover)
Mỗi lúc AI xử lý xong 1 logic dài hoặc cuộc trò chuyện kéo xuống tốn trên 150K Tokens.
- **Câu lệnh:** `Đã xong bước A. Áp dụng @core/skills/state-handover/SKILL.md để dump state xuống tệp checkpoint cho tôi.`
- **Thực thi:** AI sẽ trích ép lại ngữ cảnh (Tóm lại sửa cái gì, cần làm gì bước sau) thành 1 file JSON vài trăm kí tự. Sau đó bạn hãy mạnh dạn gõ lệnh `/compact` để dọn sạch RAM chat rác thui rụi Tokens. Chạy lại với cài đầu nhẹ bẫng!

### 3. Vận công "Lá Chắn Màn Hình" (Safe Exec)
Việc AI hoặc bạn tự quăng lệnh `npm build` hay `go test` trực tiếp sẽ nhả ra đống stack trace dài vô tận làm nhiễu sóng AI và ngốn cực đau Tokens. Hành động đó bị nghiêm cấm.
- **Làm đúng:** Hãy ép AI dùng lệnh `./core/scripts/safe-exec.sh "câu lệnh của bạn"`
- **Thực thi:** Script thông minh sẽ tự động bắt lấy khối logs đó, nén những phần lặp dài ở giữa đi và chỉ trích 40 dòng cảnh báo lỗi cốt lõi trên Top và Bottom cho AI đọc.

### 4. Ấn chỉ "Ghi Cốt Ghi Tâm" Của Token Economy
- **Câu lệnh:** `@core/rules/token-economy.md Đây là hiến pháp tối cao của hệ thống.`
- **Chỉ thị này sẽ ép con bot:** Từ bỏ thói quen bừa bãi `cat` toàn bộ nội dung file hàng ngàn dòng. Ép nó phải grep để tìm kiếm dòng chính xác trước, hoặc xài `view_file` có line range để không vượt ngưỡng chịu tải. Bắt nó ghi nhớ thiết lập Prompt Caching để tối thiểu hóa hao hụt.

---
*Hệ thống được sáng tạo dựa trên trải nghiệm tối cao của System Architect & Agentic Builders. Vận dụng đúng và bạn sẽ tiết kiệm được 95% chi phí API nhưng đem lại output đạt level Senior!*
