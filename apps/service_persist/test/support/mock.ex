Mox.defmock(Persist.DLQMock, for: Dlq.Behaviour)
Mox.defmock(Persist.LoaderMock, for: [Test.StartLink, GenServer])
Mox.defmock(Persist.CompactorMock, for: Persist.Compactor)
