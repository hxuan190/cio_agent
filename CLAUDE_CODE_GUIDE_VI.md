# 📘 Hướng Dẫn Chi Tiết: Cài Đặt & Sử Dụng Minimalist Core Agent System với Claude Code

Tài liệu này cung cấp hướng dẫn toàn diện từng bước để bạn thiết lập và sử dụng dự án **Everything Claude Code (Lõi Minimalist)** với công cụ [Claude Code](https://github.com/anthropics/claude-code) (CLI chính thức từ Anthropic). Đi kèm theo đó là các ví dụ thực tế giúp bạn ứng dụng ngay vào công việc hằng ngày.

---

## 🛠 Phần 1: Cài Đặt và Cấu Hình Hệ Thống

Để có thể tận dụng toàn bộ các thiết lập nâng cao, agent, hooks, và kịch bản tự động hóa, bạn cần phải gắn kết `core/` của repository này vào hệ sinh thái của Claude CLI.

### Bước 1: Khai báo Đường dẫn Lõi (Plugin Root)
Claude cần biết thư mục `core` được lưu ở đâu để triệu hồi các scripts và skills phù hợp.

1. Mở terminal của bạn.
2. Thêm biến môi trường `CLAUDE_PLUGIN_ROOT` vào file cấu hình shell (`~/.bashrc`, `~/.zshrc`, hoặc shell bạn đang dùng):
   ```bash
   # Mở file cấu hình bằng nano (hoặc vi/vim)
   nano ~/.zshrc 
   
   # Thêm dòng sau vào cuối file (Nhớ sửa lại chính xác đường dẫn đến repo trên máy bạn)
   export CLAUDE_PLUGIN_ROOT="/home/hxuan190/projects/ab/everything-claude-code/core"
   ```
3. Khởi động lại terminal hoặc chạy lệnh:
   ```bash
   source ~/.zshrc
   ```

### Bước 2: Tích hợp Hooks (Tự động hóa) vào Claude Code
Hooks giúp AI tự động kiểm tra, bắt lỗi hoặc dọn sạch bộ nhớ sau các thao tác lập trình.

1. Định vị thư mục chứa cấu hình của Claude mặc định trên máy bạn: `~/.claude/` (Nếu chưa có thì hãy chạy thử lệnh `claude` 1 lần trên terminal để nó tự sinh ra thư mục).
2. Mở file `~/.claude/settings.json`. Nếu file không tồn tại, bạn có thể tạo mới nó.
3. Mở file `core/hooks/hooks.json` có sẵn trong repo này, chép toàn bộ phần tử thuộc mảng `"hooks"` và dán ghép vào trong `settings.json` của bạn. 
   
   *Ví dụ file `~/.claude/settings.json` của bạn sau khi dán:*
   ```json
   {
     "theme": "dark",
     "hooks": [
       {
         "name": "auto-compress-memory",
         "description": "Tự động nén ngữ cảnh sau 15 lượt chat",
         "trigger": "post-turn",
         "script": "$CLAUDE_PLUGIN_ROOT/hooks/compress-memory.sh"
       }
       // ... các hooks khác
     ]
   }
   ```

### Bước 3: Thiết lập Giao thức Máy Chủ Đa Môi Trường (MCP Servers)
MCP giúp Claude Code có thể đọc Database, chọc vào Github, hoặc tra cứu Browser... 

1. Mở file thư mục MCP gốc của Claude CLI: `~/.claude.json`. (Nếu không có, hãy tạo mới).
2. Lấy nội dung cấu hình từ file `core/mcp-configs/mcp-servers.json` của repo này, sau đó sao chép danh sách các servers vào block `"mcpServers"`.
   
   *Ví dụ:*
   ```json
   {
     "mcpServers": {
       "github-tools": {
         "command": "node",
         "args": ["$CLAUDE_PLUGIN_ROOT/mcp-configs/github-mcp/index.js"],
         "env": {
           "GITHUB_TOKEN": "ghp_xxxxxxxxxxxxxx"
         }
       }
     }
   }
   ```
   🚨 *Lưu ý:* Đừng quên thay thế các `YOUR_KEY`, `YOUR_TOKEN` thành các Key thực tế của bạn.

---

## 🎯 Phần 2: Cách Sử Dụng và Ví Dụ Thực Tế

Sau khi cấu hình, bạn đã có một Claude Code được "độ" lên với hiệu suất token tối thượng. Hãy khởi chạy phiên làm việc bằng lệnh: `claude` ngay tại thư mục dự án của bạn (ví dụ như một dự án React web, hoặc Go backend).

Dưới đây là **4 kịch bản thực tế** sử dụng.

### Kịch bản 1: Nhờ "Kẻ Điều Phối" (Router Agent) phân tích dự án lớn
Thay vì chat thẳng: *"Làm cho tôi cái trang web bán nhạc"*, hãy để Router lên kế hoạch trước để tránh việc AI code lan man và gây lỗi hệ thống.

**Cú pháp trong Claude Code (dấu nhắc lệnh):**
> **You:** `Đọc chỉ dẫn @core/agents/router.md. Tôi muốn bắt đầu xây dựng module giỏ hàng (Cart) cho dự án thương mại điện tử bằng Next.js.`

**Cách hệ thống hoạt động:** 
AI sẽ không ngay lập tức lao vào viết code giỏ hàng. Nhờ có `router.md`, AI sẽ:
1. Khảo sát cấu trúc file hiện tại của bạn.
2. Trả ra một **Kế hoạch hành động chi tiết (Checklist)** (Ví dụ: `1. Tạo Redux store cho Cart`, `2. Tạo UI Component`, `3. Viết hooks xử lý LocalStorage`).
3. Đề xuất bạn gọi sub-agent phụ trách Coder để làm lần lượt từng bước trong Checklist.

### Kịch bản 2: Code Tối Ưu, Cấm Output Lỗi Rác Tốn Tokens (Safe Exec)
Bạn vừa code xong một hàm lớn và bảo AI chạy test gỡ lỗi. Bình thường, AI sẽ gõ `npm run test` hoặc `go build` trực tiếp trên terminal. Phản hồi lỗi rác khổng lồ từ terminal sẽ quét sạch hàng ngàn, chục ngàn tokens của bạn ngay lập tức!

**Hãy ngăn chặn điều đó bằng cách ra lệnh:**
> **You:** `Chạy test để kiểm tra logic. Yêu cầu sử dụng lớp vỏ bọc bằng lệnh ./core/scripts/safe-exec.sh "npm target_test". Mọi kết quả dù lỗi hay thành công phải thông qua wrapper này.`

**Cách hệ thống hoạt động:**
`safe-exec.sh` sẽ bắt trọn log, nén bỏ đi các stack-traces dưa thừa, chỉ trích xuất các lỗi nguyên nhân cốt lõi (ví dụ 40 dòng đầu/cuối), trả về cho Claude. Việc gỡ lỗi vẫn hoàn hảo mà không tốn Tokens cho dữ liệu vô ích.

### Kịch bản 3: Dump Memory / Bàn giao Trạng thái (State Handover)
Ngữ cảnh (Context) chat của bạn bắt đầu có quá nhiều tin nhắn (sau 1 tiếng hì hục làm việc). Bạn cảm thấy chi phí API tăng cao nhưng chưa xong task.

**Cú pháp giải quyết:**
> **You:** `Chúng ta đã xong bước 2. Áp dụng kỹ năng ở @core/skills/state-handover/SKILL.md để dump state ghi ra file JSON, sau đó tóm tắt và dừng lại.`

**Cách hệ thống hoạt động:**
1. AI đọc kĩ năng State Handover.
2. AI tự động đúc kết toàn bộ hành trình chat hiện tại thành nội dung cực ngắn và ghi đè vào một tệp (chẳng hạn `core/state/current_task_state.json`), chứa danh sách việc đã xong, việc sắp làm và file đang mở.
3. Sau đó, ở chính Claude Code, bạn có thể gõ lệnh CLI nội bộ `/compact` để dọn sách hội thoại.
4. Khi bắt đầu hội thoại mới tinh, bạn nói với AI: `Tham khảo trạng thái gần nhất trong core/state/current_task_state.json và tiếp tục làm bước 3.` => Bạn vừa tiết kiệm được cả núi tiền và RAM!

### Kịch bản 4: Check Lỗ Hổng Cơ Bản qua Rules Thép
Khi bạn tạo Pull Request, bạn muốn rà soát code lần cuối bằng hệ rules "chống lãng phí" và "bảo mật" có sẵn trong mục `rules/`.

**Cú pháp báo cáo:**
> **You:** `Dựa vào hiến pháp @core/rules/token-economy.md, kiểm tra lại cho tôi file src/Payment.jsx để xem có điểm nào tốn bộ nhớ vô ích hay vòng lặp dở tệ không?`

**Cách hệ thống hoạt động:**
AI bị ràng buộc bởi `token-economy.md`, nên sẽ tư duy rất chặt chẽ về Memory Management (quản lý vùng nhớ) và Tối ưu hóa Big O. Nó phân tích file `src/Payment.jsx` dưới bộ khung của Senior Architect thay vì coder học việc.

---
**💡 Mẹo nhỏ (Pro-Tip):**
Đừng cố nạp toàn bộ thư mục `/core/` vào trong 1 prompt. Hãy gọi các agent/skill qua ký hiệu `@` (đến đúng địa chỉ file MD hoặc thư mục) khi bạn đến chức năng tương ứng! Điều này chứng minh hiệu suất đỉnh cao của mô hình hệ thống siêu việt này.
