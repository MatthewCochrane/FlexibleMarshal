module libs.marshal.demarshaller;

import std.traits;
import std.stdio;

package interface IDemarshalStrategy
{
	void BeginDocumentDemarshal(string name);
	void EndDocumentDemarshal(string name);
	
	void BeginArrayDemarshal(T)(T val, string name);
	void EndArrayDemarshal(T)(T val, string name);

	void BeginObjectDemarshal(T)(T val, string name);
	void EndObjectDemarshal(T)(T val, string name);

	void DemarshalStructOrClass(T)(string name, ref T val);
	void DemarshalArray(T)(string name, ref T val);
	void DemarshalSingleVar(T)(string name, ref T val);
	void DemarshalEnum(T)(string name, ref T val);
	void DemarshalUnion(T)(string name, ref T val);
}

package class Demarshaller(alias InDemarshalStrategy, StorageStrategy)
{
public:
	alias InDemarshalStrategy!(StorageStrategy) DemarshalStrategy;

	//alias m_storer.SetBuffer SetBuffer;

	static if (__traits(hasMember, StorageStrategy, "SetText"))
	{
		final void SetText(const(char)[] data)
		{
			m_storer.SetText(data);
		}
	}
	else static if (__traits(hasMember, StorageStrategy, "SetBuffer"))
	{
		final void SetBuffer(const(ubyte)[] data)
		{
			m_storer.SetBuffer(data);
		}
	}
	
	void Demarshal(T)(string name, out T val)
	{
		m_demarshaller.Demarshal(name, val);
	}
	
	void Demarshal(T)(out T val)
	{
		m_demarshaller.Demarshal(val);
	}
	
	this()
	{
		m_storer = new StorageStrategy;
		m_demarshaller = new DemarshalStrategy(m_storer);
		m_demarshaller.BeginDocumentDemarshal("");
	}
	
	private:
	StorageStrategy m_storer;
	DemarshalStrategy m_demarshaller;
}

mixin template DemarshalMixinTemplate(StorageStrategy)
{
	void DemarshalStructOrClass(T)(string name, ref T val)
	{
		static if (__traits(hasMember, T, "BeginObjectDemarshal") && __traits(hasMember, T, "EndObjectDemarshal")
				&& (isSomeFunction!(T.BeginObjectDemarshal!(typeof(this), StorageStrategy)) 
				&& (is(TemplateArgsOf!(T.BeginObjectDemarshal!(typeof(this), StorageStrategy))[0] == typeof(this))
				&&  is(TemplateArgsOf!(T.BeginObjectDemarshal!(typeof(this), StorageStrategy))[1] == StorageStrategy)))
				&& (isSomeFunction!(T.EndObjectDemarshal!(typeof(this), StorageStrategy)) 
				&& (is(TemplateArgsOf!(T.EndObjectDemarshal!(typeof(this), StorageStrategy))[0] == typeof(this))
				&&  is(TemplateArgsOf!(T.EndObjectDemarshal!(typeof(this), StorageStrategy))[1] == StorageStrategy))))
		{
			val.BeginObjectDemarshal!(typeof(this), StorageStrategy)(storer, name);
			foreach (item; __traits(allMembers, T))
			{
				static if (__traits(compiles, Demarshal(item, __traits(getMember, val, item)))
						&& !isSomeFunction!(typeof(__traits(getMember, val, item))))
				{
					Demarshal(item, __traits(getMember, val, item));
				}
			}
			val.EndObjectDemarshal!(typeof(this), StorageStrategy)(storer, name);
		}
		else 
		{
			BeginObjectDemarshal(name, val);
			foreach (item; __traits(allMembers, T))
			{
				static if (__traits(compiles, Demarshal(item, __traits(getMember, val, item)))
						&& !isSomeFunction!(typeof(__traits(getMember, val, item))))
				{
					Demarshal(item, __traits(getMember, val, item));
//					writefln("Demarshal: %s, %s", item, to!string(__traits(getMember, val, item)));
				}
			}
			EndObjectDemarshal(name, val);
		}
	}
	
	void DemarshalArray(T)(string name, ref T val)
	{
		static if (__traits(hasMember, T, "BeginArrayDemarshal") && __traits(hasMember, T, "EndArrayDemarshal")
				&& (isSomeFunction!(T.BeginArrayDemarshal!(typeof(this), StorageStrategy)) 
				&& (is(TemplateArgsOf!(T.BeginArrayDemarshal!(typeof(this), StorageStrategy))[0] == typeof(this))
				&&  is(TemplateArgsOf!(T.BeginArrayDemarshal!(typeof(this), StorageStrategy))[1] == StorageStrategy)))
				&& (isSomeFunction!(T.EndArrayDemarshal!(typeof(this), StorageStrategy)) 
				&& (is(TemplateArgsOf!(T.EndArrayDemarshal!(typeof(this), StorageStrategy))[0] == typeof(this))
				&&  is(TemplateArgsOf!(T.EndArrayDemarshal!(typeof(this), StorageStrategy))[1] == StorageStrategy))))
		{
			//Begin
			val.BeginArrayDemarshal!(typeof(this), StorageStrategy)(storer, name);
			
			int i = 0;
			val = [];
			ForeachType!(T) item;
			try
			{
				while (true)
				{
					Demarshal(to!string(i), item);
					val ~= item;
					++i;
				}
			}
			catch (InvalidFormattingException ex)
			{
			}
			
			//End
			val.EndArrayDemarshal!(typeof(this), StorageStrategy)(storer, name);
		}
		else 
		{
			//Begin
			BeginArrayDemarshal(name, val);
			
			static if (__traits(hasMember, typeof(this), "LoopArrayDemarshal") && 
				isSomeFunction!(typeof(this).LoopArrayDemarshal!(T)))
			{
				LoopArrayDemarshal(name, val);
			}
			else
			{
				int i = 0;
				val = [];
				ForeachType!(T) item;
				try
				{
					while (true)
					{
						Demarshal(to!string(i), item);
						val ~= item;
						++i;
					}
				}
				catch (InvalidFormattingException ex)
				{
				}
			}
			
			//End
			EndArrayDemarshal(name, val);
		}
	}
	
	void Demarshal(T)(string name, ref T val) 
	{
		static if (__traits(hasMember, T, "Demarshal") 
					&& isSomeFunction!(T.Demarshal!(typeof(this), StorageStrategy))
					&& (is(TemplateArgsOf!(T.Demarshal!(typeof(this), StorageStrategy))[0] == typeof(this))
					&&  is(TemplateArgsOf!(T.Demarshal!(typeof(this), StorageStrategy))[1] == StorageStrategy)))
		{
			val.Demarshal!(typeof(this), StorageStrategy)(m_storer, name);
		}
		else static if (is(T == struct) || is(T == class))
		{
			DemarshalStructOrClass(name, val);
		}
		else static if (isArray!(T) && !isSomeString!(T))
		{
			DemarshalArray(name, val);
		}
		else static if (__traits(isPOD, T))
		{
			DemarshalSingleVar(name, val);
		}
	}
	
	private StorageStrategy m_storer;
	
	package this(StorageStrategy storer)
	{
		this.m_storer = storer;
	}

}
