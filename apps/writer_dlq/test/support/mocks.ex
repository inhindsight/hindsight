Mox.defmock(WriterMock, for: Writer)
Application.put_env(:writer_dlq, :writer, WriterMock)
