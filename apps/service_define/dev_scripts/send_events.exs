id = "My-id"

extract_event =
    Extract.new!(
    id: "extract-1",
    dataset_id: id,
    subset_id: "default",
    destination: "success",
    dictionary: [
        Dictionary.Type.String.new!(name: "letter")
    ],
    steps: [
        Extract.Http.Get.new!(
        url: "http://localhost/file.csv",
        headers: %{"content-length" => "5"}
        )
    ]
    )

Brook.Event.send(Define.Application.instance(), "extract:start", "self", extract_event)
