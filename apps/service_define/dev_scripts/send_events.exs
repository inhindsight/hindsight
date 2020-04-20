id = "My-id"

extract = Extract.new!(
            version: 1,
            id: "map-data-extract-1",
            dataset_id: "map-data-datasetid",
            subset_id: "map-data-subset",
            destination:
              Kafka.Topic.new!(
                endpoints: ["hindsight-hindsight-kafka-bootstrap": 9092],
                name: "map-data-gather"
              ),
            source:
              Extractor.new!(
                steps: [
                  Extract.Http.Get.new!(url: "https://ade-public-files.s3.us-east-2.amazonaws.com/SampleMapData2.json")
                ]
              ),
            decoder: Decoder.Json.new!([]),
            dictionary: [
                Dictionary.Type.List.new!(
                    name: "intersections",
                    item_type:
                    Dictionary.Type.Map.new!(
                        name: "intersection",
                        dictionary: [
                            Dictionary.Type.Integer.new!(name: "id"),
                            Dictionary.Type.Map.new!(
                                name: "position",
                                dictionary: [
                                    Dictionary.Type.Integer.new!(name: "x"),
                                    Dictionary.Type.Integer.new!(name: "y")
                                ]
                            ),
                            Dictionary.Type.Integer.new!(name: "peopleServed")
                        ]
                    )
                ),
                Dictionary.Type.List.new!(
                    name: "streets",
                    item_type:
                    Dictionary.Type.Map.new!(
                        name: "street",
                        dictionary: [
                            Dictionary.Type.Integer.new!(name: "id"),
                            Dictionary.Type.Integer.new!(name: "sourceId"),
                            Dictionary.Type.Integer.new!(name: "destinationId")
                        ]
                    )
                )
            ]
        )

Brook.Event.send(Define.Application.instance(), "extract:start", "self", extract)
