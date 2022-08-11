import 'package:xml_parser/xml_parser.dart';

class ServerConfig {
  ServerConfig(
    this.ignoreIds,
  );

  /// Factory constructor for creating a new ServerConfig from a [XmlElement].
  ServerConfig.fromXMLElement(XmlElement? element)
      : ignoreIds = element!.getAttribute('ignoreids')!;

  String ignoreIds;
}
