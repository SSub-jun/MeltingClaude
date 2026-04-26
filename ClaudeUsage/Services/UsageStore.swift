import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class UsageStore {
    static let shared = UsageStore()

    private var db: OpaquePointer?
    private let dbURL: URL
    private let queue = DispatchQueue(label: "ClaudeUsage.UsageStore")

    static var dataFolder: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Claude Usage", isDirectory: true)
    }

    private init() {
        let folder = Self.dataFolder
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        dbURL = folder.appendingPathComponent("usage.sqlite")

        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            print("⚠️ DB open failed: \(String(cString: sqlite3_errmsg(db)))")
        }
        createTableIfNeeded()
        migrate()
    }

    deinit { if db != nil { sqlite3_close(db) } }

    private func createTableIfNeeded() {
        let sql = """
        CREATE TABLE IF NOT EXISTS usage_records (
            id TEXT PRIMARY KEY,
            created_at REAL NOT NULL,
            model TEXT NOT NULL,
            input_tokens INTEGER NOT NULL,
            output_tokens INTEGER NOT NULL,
            total_tokens INTEGER NOT NULL,
            estimated_cost_usd REAL NOT NULL,
            project_path TEXT,
            source TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_usage_created_at ON usage_records(created_at);
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    /// 기존 DB에 external_id 없으면 추가 (이미 있으면 ALTER 실패하지만 무시)
    private func migrate() {
        sqlite3_exec(db, "ALTER TABLE usage_records ADD COLUMN external_id TEXT", nil, nil, nil)
        // 부분 UNIQUE 인덱스 (NULL 허용, NOT NULL은 유일)
        sqlite3_exec(db,
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_usage_external_id ON usage_records(external_id) WHERE external_id IS NOT NULL",
            nil, nil, nil)
    }

    func insert(_ r: UsageRecord) {
        insertIfNew(r, externalId: nil)
    }

    /// external_id 가 이미 있으면 무시. mock 데이터는 externalId=nil 로 호출되어 항상 INSERT 됨.
    func insertIfNew(_ r: UsageRecord, externalId: String?) {
        queue.sync {
            let sql = """
            INSERT OR IGNORE INTO usage_records
            (id, created_at, model, input_tokens, output_tokens,
             total_tokens, estimated_cost_usd, project_path, source, external_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_text(stmt, 1, r.id.uuidString, -1, SQLITE_TRANSIENT)
            sqlite3_bind_double(stmt, 2, r.createdAt.timeIntervalSince1970)
            sqlite3_bind_text(stmt, 3, r.model, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 4, Int32(r.inputTokens))
            sqlite3_bind_int(stmt, 5, Int32(r.outputTokens))
            sqlite3_bind_int(stmt, 6, Int32(r.totalTokens))
            sqlite3_bind_double(stmt, 7, r.estimatedCostUSD)
            if let p = r.projectPath {
                sqlite3_bind_text(stmt, 8, p, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(stmt, 8)
            }
            sqlite3_bind_text(stmt, 9, r.source, -1, SQLITE_TRANSIENT)
            if let ext = externalId {
                sqlite3_bind_text(stmt, 10, ext, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(stmt, 10)
            }

            sqlite3_step(stmt)
        }
    }

    func fetch(since: Date? = nil, limit: Int? = nil) -> [UsageRecord] {
        queue.sync {
            var sql = """
            SELECT id, created_at, model, input_tokens, output_tokens,
                   total_tokens, estimated_cost_usd, project_path, source
            FROM usage_records
            """
            if since != nil { sql += " WHERE created_at >= ?" }
            sql += " ORDER BY created_at DESC"
            if let limit { sql += " LIMIT \(limit)" }

            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
            defer { sqlite3_finalize(stmt) }

            if let since {
                sqlite3_bind_double(stmt, 1, since.timeIntervalSince1970)
            }

            var out: [UsageRecord] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                let idStr   = String(cString: sqlite3_column_text(stmt, 0))
                let created = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 1))
                let model   = String(cString: sqlite3_column_text(stmt, 2))
                let proj: String? = sqlite3_column_type(stmt, 7) == SQLITE_NULL
                    ? nil
                    : String(cString: sqlite3_column_text(stmt, 7))

                out.append(UsageRecord(
                    id: UUID(uuidString: idStr) ?? UUID(),
                    createdAt: created,
                    model: model,
                    inputTokens:  Int(sqlite3_column_int(stmt, 3)),
                    outputTokens: Int(sqlite3_column_int(stmt, 4)),
                    totalTokens:  Int(sqlite3_column_int(stmt, 5)),
                    estimatedCostUSD: sqlite3_column_double(stmt, 6),
                    projectPath: proj,
                    source: String(cString: sqlite3_column_text(stmt, 8))
                ))
            }
            return out
        }
    }

    /// 통계용: 총 record 수
    func count() -> Int {
        queue.sync {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM usage_records", -1, &stmt, nil) == SQLITE_OK else { return 0 }
            defer { sqlite3_finalize(stmt) }
            if sqlite3_step(stmt) == SQLITE_ROW {
                return Int(sqlite3_column_int(stmt, 0))
            }
            return 0
        }
    }
}
