module libs.marshal.text_demarshaller;

import std.conv, std.algorithm;
import std.stdio;

package interface ITextDemarshalerStorageStrategy 
{
package:
	string GetBuffer();
	void SetText(const(char)[] dat);

	void Expect(string text);
	int  ChompWhitespace();
	void ReadValAndExpect(T)(out T val, string expect);

    void SetNewLineString(string value);
}

public class InvalidFormattingException : Exception
{
	this(string s) { super(s); }
}

package class TextDemarshallerStorageStrategy : ITextDemarshalerStorageStrategy
{
package:
	this() {}

	this(string data)
	{
		SetText(data);
	}

	final string GetBuffer()
	{
		return m_buffer.idup;
	}
	
	final void SetText(const(char)[] data)
	{
		m_buffer = data.dup;
		m_cursor = 0;
	} 
	
	final void Expect(string text)
	{
		if (m_buffer[m_cursor .. m_cursor + text.length] == text)
		{
			m_cursor += text.length;
		}
		else
		{
			throw new InvalidFormattingException("In Expect");
		}
	}
	
	final int ChompWhitespace()
	{
		int chars_chomped = 0;
		//TODO: more compact code for this?
		while (m_cursor + chars_chomped < m_buffer.length &&
			   (m_buffer[m_cursor + chars_chomped] == '\t' ||
			    m_buffer[m_cursor + chars_chomped] == ' '  ||
			    m_buffer[m_cursor + chars_chomped] == '\r' ||
			    m_buffer[m_cursor + chars_chomped] == '\n'))
		{
			++chars_chomped;
		}
		m_cursor += chars_chomped;
		return chars_chomped;
	}
	
	final void ReadValAndExpect(T)(out T val, string expect)
	{
		auto pos = find(m_buffer[m_cursor .. $], expect);
		if (pos != m_buffer[m_cursor .. $])
		{
			int len = &pos[0] - &m_buffer[m_cursor];
			val = to!T(m_buffer[m_cursor .. m_cursor + len]);
			m_cursor += len + expect.length;
		}
		else
		{
			throw new InvalidFormattingException("");
		}
	}
	
    final void SetNewLineString(string value)
	{
		m_newline_string = value;
	}
	
private:

	char[] m_buffer;
	string m_newline_string = "\r\n";
	int m_cursor = 0;
	
	unittest {
		TextDemarshallerStorageStrategy tm = new TextDemarshallerStorageStrategy;
		tm.SetText("   \t<a>66</a>\r\n");

		assert(tm.ChompWhitespace() == 4); 

		tm.Expect("<a>");
		
		int result;
		
		tm.ReadValAndExpect(result, "</a>");
		assert(result == 66);

		tm.Expect("\r\n");
		//assert(tm.ChompWhitespace() == 2);

	}
}