import std.stdio, std.conv, std.file;
import libs.marshal.all;

class A
{
	int x = 0;
	float y[] = [1.1, 2.2, 33.3];
	string value = "hi there";
}

class B
{
	A a;
	enum Type {Cat, Dog, Person, Fish};
	Type type = Type.Fish;
}

void main() {
	B b = new B;
	b.a = new A;
	writeln("start");
	
	XmlTextMarshaller xml_marshaller = new XmlTextMarshaller;
	xml_marshaller.Marshal(b, "b");
	std.file.write("testfile.xml", xml_marshaller.ToString());
	
	HumanReadableTextMarshaller human_readable_marshaller = new HumanReadableTextMarshaller;
	human_readable_marshaller.Marshal(b, "b");
	std.file.write("testfile.txt", human_readable_marshaller.ToString());
}
