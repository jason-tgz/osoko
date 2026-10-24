import Foundation

public final class ExportTracker: @unchecked Sendable {
    public static let shared = ExportTracker()

    private let lock = NSLock()
    private var exportedPaths: Set<String> = []

    private init() {}

    public func register(url: URL) {
        lock.lock()
        defer { lock.unlock() }
        let resolved = url.standardizedFileURL.resolvingSymlinksInPath().path
        exportedPaths.insert(resolved)
        exportedPaths.insert(url.path)
    }

    public func isExported(url: URL) -> Bool {
        lock.lock()
        let resolved = url.standardizedFileURL.resolvingSymlinksInPath().path
        let contains = exportedPaths.contains(resolved) || exportedPaths.contains(url.path)
        lock.unlock()

        if contains { return true }

        // Also check extended attribute on file if present
        return url.withUnsafeFileSystemRepresentation { p in
            guard let p else { return false }
            return getxattr(p, "com.osoko.saved", nil, 0, 0, 0) >= 0
        }
    }
}
