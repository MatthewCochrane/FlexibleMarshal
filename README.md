# FlexibleMarshal
A flexible marshaller/demarshaller for D.


This library implements marshaling functionality for converting data into formats that are more easily saved or interpreted by humans and possibly back again.
The library is broken into parts.  The main two files are:
  1. marshaller.d
  2. demarshaller.d

These files define the root of the marshaller/demarshaller.


## Marshallers
marshaller.d is responsible only for defining the root functionality of a marshaller.  It does not contain any of the specifics about how structures are marshalled or in what format they are stored.
Two different components are needed to form a fully functional marshaller:
  1. A (Marshal)StorageStrategy
  2. A MarshalStrategy
  
A StorageStrategy defines how the marshaller will store the data.  For example it may be stored in text format or binary format.  Storage strategies for text and binary are both defined in the files text_marshaller.d and binary_marshaller.d.  
A MarshalStrategy defines the specifics of what is to be marshalled.  It only makes sense to use a MarshalStrategy with a single kind of StorageStrategy, as each StorageStrategy defines a different api.  For example, the TextMarshaller StorageStrategy implements marshal strategies for conversion to XML, JSON and to a human readable format.

To define a MarshalStrategy, copy the code from a similar strategy such as 
xml_text_marshaller.d.  There are a few key things that are required in such a file:
  1. Importing the main marshaller file: libs.marshal.marshaller
  2. Importing the file containing your StorageStrategy, eg. libs.marshal.text_marshaller;
  3. Creating an alias so the marshaller can be used externally, eg. 
  
  ```alias Marshaller!(XmlMarshallerStrategy, TextMarshallerStorageStrategy) XmlTextMarshaller;```
  4. Create a class that is templated and implements IMarshalStrategy.  The first line of the body of this class should be a template mixin.  See example below:
  
  ```
  package class XmlMarshallerStrategy(StorageStrategy) : IMarshalStrategy
  {
    mixin MarshalMixinTemplate!(StorageStrategy);
    ...
  }
  ```
  
    It also needs to implement the member functions from IMarshalStrategy.  Some of these are
    templated and will fail silently if not implemented so make sure you check.

## Demarshallers
demarshaller.d is responsible only for defining the root functionality of a demarshaller. It does not contain any of the specifics about how structures are demarshalled or how the
stored data should be interpreted. Two different components are needed to form a fully functional demarshaller:
  1. A (Demarshal)StorageStrategy
  2. A DemarshalStrategy
A StorageStrategy defines how the demarshaller will interpret the stored data.  For example data may be read in text or binary format.  Storage strategies for text and binary are both defined in the files text_demarshaller.d and binary_demarshaller.d.  

A DemarshalStrategy defines the specifics of what is to be demarshalled.  It only makes sense to use a DemarshalStrategy with a single kind of StorageStrategy, as each StorageStrategy defines a different api.  For example, the TextDemarshaller StorageStrategy implements demarshal strategies for interpretation from XML and JSON.
