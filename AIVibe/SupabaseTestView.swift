//
//  SupabaseTestView.swift
//  AIVibe
//
//  Created by Sarah Zhang on 12/29/25.
//  Claude edit with Chinese prompts 1/1/26

import SwiftUI
import Supabase

// 初始化 Supabase Client - remove line above that said /Users/sarahzhang/Documents/AIVibe/SupabaseTestView.swift
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://eujoyccryuwhxtqceqgy.supabase.co")!,
    supabaseKey: "sb_publishable_fxj3f5-PGjWJpmKcLBdfPg_M__xU71j"
)

struct SupabaseTestView: View {
    @State private var isConnected: Bool? = nil
    @State private var logMessage: String = "点击按钮开始测试链接..."
    @State private var isTesting: Bool = false

    var body: some View {
        VStack(spacing: 30) {
            // 状态图标
            Group {
                if let connected = isConnected {
                    if connected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                    }
                } else {
                    Image(systemName: "network")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 40)

            // 调试日志文本框
            ScrollView {
                Text(logMessage)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            .frame(height: 200)
            .padding(.horizontal)

            // 测试连接按钮
            Button(action: testConnection) {
                HStack {
                    if isTesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isTesting ? "测试中..." : "测试连接")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isTesting ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isTesting)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Supabase 链接测试")
    }

    // 测试连接逻辑
    func testConnection() {
        isTesting = true
        logMessage = "正在测试链接...\n"

        Task {
            do {
                // 故意查询一个不存在的表来测试连接
                _ = try await supabase
                    .from("non_existent_table")
                    .select()
                    .execute()

                // 如果没有抛出错误（理论上不会到这里）
                await MainActor.run {
                    isConnected = true
                    logMessage += "✅ 链接成功（意外：表存在）\n"
                    isTesting = false
                }

            } catch {
                // 分析错误类型来判断连接状态
                let errorMessage = error.localizedDescription
                let fullError = "\(error)"

                await MainActor.run {
                    logMessage += "收到错误: \(errorMessage)\n"
                    logMessage += "完整错误: \(fullError)\n\n"

                    // 判断连接是否成功
                    if errorMessage.contains("PGRST") ||
                       fullError.contains("PGRST") ||
                       errorMessage.contains("Could not find the table") ||
                       errorMessage.contains("relation") && errorMessage.contains("does not exist") ||
                       fullError.contains("relation") && fullError.contains("does not exist") ||
                       errorMessage.contains("42P01") ||
                       fullError.contains("42P01") {

                        isConnected = true
                        logMessage += "✅ lian接成功（服务器已响应）\n"
                        logMessage += "说明：收到数据库错误响应，证明已成功连接到 Supabase\n"

                    } else if errorMessage.contains("hostname") ||
                              errorMessage.contains("URL") ||
                              errorMessage.contains("NSURLErrorDomain") ||
                              errorMessage.contains("could not be found") {

                        isConnected = false
                        logMessage += "❌ 链接失败：URL 错误或无网络\n"
                        logMessage += "请检查：\n"
                        logMessage += "1. 网络链接是否正常\n"
                        logMessage += "2. Supabase URL 是否正确\n"
                        logMessage += "3. macOS 网络权限设置\n"

                    } else {
                        isConnected = false
                        logMessage += "❌ 未知错误\n"
                        logMessage += "详细信息：\(errorMessage)\n"
                    }

                    isTesting = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SupabaseTestView()
    }
}
