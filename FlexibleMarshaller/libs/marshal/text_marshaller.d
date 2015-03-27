module libs.marshal.text_marshaller;

package interface ITextMarshalerStorageStrategy 
{
package:
	string GetBuffer();
    void ClearBuffer();

    void AddText(string text);
    void AddLine(string text);

    void SetIndentation(uint value);
    void IncrmentIndentation();
    void IncreaseIndentation(uint value);
    void DecrementIndentation();
    void DecreaseIndentation(uint value);

    void SetIndentationString(string value);
    void SetNewLineString(string value);
}

package class TextMarshallerStorageStrategy : ITextMarshalerStorageStrategy
{
package:
	final string GetBuffer()
	{
		return m_buffer.idup;
	} 
	
	final void ClearBuffer()
	{
		m_buffer = [];
		m_indententation_amounts = [];
	}
	
	final void AddText(string text)
	{
		m_buffer ~= text;
	}
	
	final void AddLine(string text)
	{
		m_buffer ~= repeat_string(m_indentation_string, m_current_indentation_count) ~ text ~ m_newline_string;
	}
	
	final void SetIndentation(uint value)
	{
		m_current_indentation_count = value;
		m_indententation_amounts = [];
	}
	
    final void IncrementIndentation()
	{
		++m_current_indentation_count;
		m_indententation_amounts ~= 1;
	}
	
    final void IncreaseIndentation(uint value)
	{
		m_current_indentation_count += value;
		m_indententation_amounts ~= value;
	}
	
    final void DecrementIndentation()
	{
		--m_current_indentation_count;
		m_indententation_amounts ~= -1; 
	}
	
    final void DecreaseIndentation(uint value)
	{
		m_current_indentation_count -= value;
		m_indententation_amounts ~= -value;
	}
	
	final void UndoLastIndentation()
	{
		if (m_indententation_amounts.length > 0)
		{
			m_current_indentation_count -= m_indententation_amounts[$-1];
			m_indententation_amounts = m_indententation_amounts[0 .. $-1];
		}
	}
	
    final void SetIndentationString(string value)
	{
		m_indentation_string = value;
	}
	
    final void SetNewLineString(string value)
	{
		m_newline_string = value;
	}
	
private:
	static final pure string repeat_string(string string_to_repeat, int repetitions)
	{
		char[] retval;
		retval.length = string_to_repeat.length * repetitions;
		if (string_to_repeat == "") return "";
		for (int i = 0; i < repetitions; ++i)
		{
			retval[i*string_to_repeat.length .. (i+1)*string_to_repeat.length] = string_to_repeat;
		} 
		return retval.idup;
	}

	int[] m_indententation_amounts = [];
	char[] m_buffer;
	uint m_current_indentation_count = 0;
	string m_indentation_string = "\t";
	string m_newline_string = "\r\n";
	
	unittest {
		assert(repeat_string("123", 3) == "123123123");
		assert(repeat_string("", 123456) == "");
		assert(repeat_string("a", 10) == "aaaaaaaaaa");
		assert(repeat_string("a", 0) == "");
		
		TextMarshallerStorageStrategy tm = new TextMarshallerStorageStrategy;
		tm.AddLine("<a>");
		tm.IncrementIndentation();
		tm.AddLine("<b>test</b>");
		tm.DecrementIndentation();
		tm.AddLine("</a>");
		
		assert(tm.GetBuffer() == "<a>\r\n\t<b>test</b>\r\n</a>\r\n");
		
		tm.ClearBuffer();
		
		assert(tm.GetBuffer() == "");
		
		tm.IncreaseIndentation(10);
		tm.IncreaseIndentation(5);
		assert(tm.m_current_indentation_count == 15);
		tm.UndoLastIndentation();
		assert(tm.m_current_indentation_count == 10);
		tm.IncrementIndentation();
		assert(tm.m_current_indentation_count == 11);
		tm.UndoLastIndentation();
		tm.UndoLastIndentation();
		assert(tm.m_current_indentation_count == 0);
		
		//Can call this when there are no undos left and it doesn't crash
		tm.UndoLastIndentation();
		tm.UndoLastIndentation();
		tm.UndoLastIndentation();



	}
}