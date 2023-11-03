import Foundation

fileprivate let LOGGER_LABEL = "com.statsig.event_logger"

typealias EventFlushCompletion = (_ error: Error?) -> Void

class EventLogger {

    var options: StatsigOptions?

    private let queue = DispatchQueue(label: LOGGER_LABEL)
    private let network: NetworkService
    private let emitter: StatsigClientEventEmitter

    private var events: [StatsigEventInternal] = []
    private var flushTimer: Timer?

    init(_ network: NetworkService,
         _ emitter: StatsigClientEventEmitter) {
        self.network = network
        self.emitter = emitter

        DispatchQueue.main.async { [weak self] in
            self?.startFlushTimer()
        }
    }

    func enqueue(_ eventFactory: @escaping () -> StatsigEventInternal) {
        self.enqueueImpl(eventFactory)
    }

    func shutdown(completion: EventFlushCompletion? = nil) {
        self.flushTimer?.invalidate()
        self.flush(completion)
    }

    func flush(_ completion: EventFlushCompletion? = nil) {
        let pending = queue.sync {
            let result = events
            events = []
            return result
        }

        if (pending.isEmpty) {
            return
        }

        network.post(
            .logEvent,
            payload: [
                "events": pending.map { $0.toLoggable() },
                "statsigMetadata": StatsigMetadata.get().toLoggable()
            ],
            retries: 3
        ) { [weak emitter] (result: DecodedResult<LogEventResponse>?, error) in
            completion?(error)
            emitter?.emit(.eventsFlushed, [
                "events": pending,
                "success": error == nil && result?.decoded.success == true
            ])
        }
    }

    private func enqueueImpl(_ eventFactory: () -> StatsigEventInternal) {
        let shouldFlush = queue.sync {
            let event = eventFactory()
            events.append(event)

            let max = options?.eventQueueMaxSize ?? StatsigOptions.Defaults.eventQueueMaxSize
            return events.count >= max
        }

        if (shouldFlush) {
            flush()
        }
    }

    private func startFlushTimer() {
        flushTimer?.invalidate()

        let interval = options?.eventQueueInternalMs ?? StatsigOptions.Defaults.eventQueueInternalMs

        flushTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(interval) / 1000.0,
            repeats: true
        ) { [weak self] _ in
            self?.flush()
        }
    }
}
