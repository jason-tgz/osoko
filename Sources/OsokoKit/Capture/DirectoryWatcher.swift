import Foundation

final class DirectoryWatcher: @unchecked Sendable {
    private let url: URL
    private var source: DispatchSourceFileSystemObject?
    private var knownFiles: Set<String> = []
    private let onNewFile: @Sendable (URL) -> Void
    private let queue = DispatchQueue(label: "com.osoko.directoryWatcher", qos: .userInitiated)

    init(url: URL, onNewFile: @escaping @Sendable (URL) -> Void) {
        self.url = url
        self.onNewFile = onNewFile
        self.knownFiles = Set(listFiles().map(\.path))
    }

    func start() {
        guard source == nil else { return }
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: queue
        )

        src.setEventHandler { [weak self] in
            self?.scan()
        }

        src.setCancelHandler {
            close(fd)
        }

        source = src
        src.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    private func listFiles() -> [URL] {
        let resolved = url.resolvingSymlinksInPath()
        return (try? FileManager.default.contentsOfDirectory(
            at: resolved,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ))?.map { $0.standardizedFileURL.resolvingSymlinksInPath() } ?? []
    }

    private func scan() {
        let current = listFiles()
        var hasPendingIncomplete = false

        for file in current {
            let path = file.path
            guard !knownFiles.contains(path) else { continue }
            guard let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize, size > 100 else {
                continue
            }
            if ExportTracker.shared.isExported(url: file) {
                knownFiles.insert(path)
                continue
            }
            if ScreenshotCaptureService.isImageFile(file) {
                guard ScreenshotCaptureService.isFullyWrittenImage(file) else {
                    hasPendingIncomplete = true
                    continue
                }
            }
            knownFiles.insert(path)
            onNewFile(file)
        }

        if hasPendingIncomplete {
            queue.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.scan()
            }
        }
    }
}
