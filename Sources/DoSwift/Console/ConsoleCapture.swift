//
//  ConsoleCapture.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import Foundation

extension DO {

    final class ConsoleCapture {

        static let shared = DO.ConsoleCapture()
        private init() {}

        var onLine: ((DO.ConsoleLine) -> Void)?

        var onContinuation: ((DO.ConsoleLine.Source, String) -> Void)?

        private let queue = DispatchQueue(label: "com.doswift.console.capture")

        private let chunkSize = 4096

        private let maxPendingBytes = 64 * 1024

        private final class Stream {

            let fd: Int32

            let source: DO.ConsoleLine.Source

            let original: Int32

            let readEnd: Int32

            var pending = Data()

            var openBrackets = 0

            var mergedLines = 0

            func resetContinuation() {
                openBrackets = 0
                mergedLines = 0
            }

            var lastDelivery = Date.distantPast

            var dispatchSource: DispatchSourceRead?

            init(fd: Int32, source: DO.ConsoleLine.Source, original: Int32, readEnd: Int32) {
                self.fd = fd
                self.source = source
                self.original = original
                self.readEnd = readEnd
            }
        }

        private var streams: [Stream] = []

        private(set) var isRunning = false

        func start() {
            guard !isRunning else { return }
            isRunning = true

            attach(fd: STDOUT_FILENO, source: .standardOutput)
            attach(fd: STDERR_FILENO, source: .standardError)
        }

        func stop() {
            guard isRunning else { return }
            isRunning = false

            fflush(stdout)
            fflush(stderr)

            setvbuf(stdout, nil, _IOFBF, Int(BUFSIZ))
            setvbuf(stderr, nil, _IOFBF, Int(BUFSIZ))

            for stream in streams {
                guard stream.original >= 0 else { continue }
                dup2(stream.original, stream.fd)
                close(stream.original)
            }

            queue.sync {
                for stream in streams {
                    drain(stream.source)
                    flushTail(of: stream)
                }
            }

            for stream in streams { stream.dispatchSource?.cancel() }
            streams.removeAll()
        }

        private func attach(fd: Int32, source: DO.ConsoleLine.Source) {
            var ends: [Int32] = [0, 0]
            guard pipe(&ends) == 0 else { return }
            let readEnd = ends[0]
            let writeEnd = ends[1]

            let original = dup(fd)

            _ = fcntl(writeEnd, F_SETNOSIGPIPE, 1)
            if original >= 0 { _ = fcntl(original, F_SETNOSIGPIPE, 1) }

            _ = fcntl(readEnd, F_SETFL, O_NONBLOCK)

            setvbuf(stdout, nil, _IOLBF, 0)
            setvbuf(stderr, nil, _IOLBF, 0)

            dup2(writeEnd, fd)

            close(writeEnd)

            let stream = Stream(fd: fd, source: source, original: original, readEnd: readEnd)
            let dispatchSource = DispatchSource.makeReadSource(fileDescriptor: readEnd, queue: queue)
            dispatchSource.setEventHandler { [weak self] in
                self?.drain(source)
            }
            dispatchSource.setCancelHandler { close(readEnd) }
            stream.dispatchSource = dispatchSource
            streams.append(stream)
            dispatchSource.resume()
        }

        private func drain(_ source: DO.ConsoleLine.Source) {
            guard let stream = streams.first(where: { $0.source == source }) else { return }

            var buffer = [UInt8](repeating: 0, count: chunkSize)
            while true {
                let count = read(stream.readEnd, &buffer, buffer.count)
                guard count > 0 else { break }

                stream.pending.append(contentsOf: buffer[0..<count])
                emitLines(from: stream)

                if stream.pending.count > maxPendingBytes { flushTail(of: stream) }
            }
        }

        private func emitLines(from stream: Stream) {
            while let breakIndex = stream.pending.firstIndex(of: 0x0A) {
                let lineData = stream.pending[stream.pending.startIndex..<breakIndex]
                let resumeIndex = stream.pending.index(after: breakIndex)
                stream.pending.removeSubrange(stream.pending.startIndex..<resumeIndex)

                var text = String(decoding: lineData, as: UTF8.self)
                if text.hasSuffix("\r") { text.removeLast() }

                deliver(text, from: stream)
            }
        }

        private let continuationGap: TimeInterval = 0.5

        private let maxContinuationLines = 30

        private func deliver(_ text: String, from stream: Stream) {
            let now = Date()

            if now.timeIntervalSince(stream.lastDelivery) > continuationGap {
                stream.resetContinuation()
            }
            stream.lastDelivery = now

            if stream.openBrackets > 0 {
                if Self.startsWithCloser(text) { stream.openBrackets -= 1 }
                stream.mergedLines += 1

                if stream.mergedLines <= maxContinuationLines {
                    onContinuation?(stream.source, text)
                    return
                }
                stream.resetContinuation()
            }

            if Self.endsWithOpener(text) {
                stream.openBrackets += 1
                stream.mergedLines = 0
            }
            onLine?(DO.ConsoleLine(date: now, source: stream.source, text: text))
        }

        private static func endsWithOpener(_ text: String) -> Bool {
            guard let last = text.last(where: { !$0.isWhitespace }) else { return false }
            return last == "(" || last == "{" || last == "["
        }

        private static func startsWithCloser(_ text: String) -> Bool {
            guard let first = text.first(where: { !$0.isWhitespace }) else { return false }
            return first == ")" || first == "}" || first == "]"
        }

        private func flushTail(of stream: Stream) {
            guard !stream.pending.isEmpty else { return }

            let text = String(decoding: stream.pending, as: UTF8.self)
            stream.pending.removeAll()
            deliver(text, from: stream)
        }
    }
}
