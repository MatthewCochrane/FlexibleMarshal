module libs.marshal.marshaller;

import std.traits;
import std.stdio;
import std.conv;

package interface IMarshalStrategy
{
	void BeginDocumentMarshal(string name);
	void EndDocumentMarshal(string name);

	void BeginObjectMarshal(T)(T val, string name);
	void EndObjectMarshal(T)(T val, string name);
	
	void BeginArrayMarshal(T)(T val, string name);
	void EndArrayMarshal(T)(T val, string name);

	void MarshalClassOrStruct(T)(T val, string name);
	void MarshalArray(T)(StorageStrategy storer, T val, string name);
	void MarshalSingleVar(T)(T val, string name);
	void MarshalEnum(T)(T val, string name);
	void MarshalUnion(T)(T val, string name);
}

package class Marshaller(alias InMarshalStrategy, StorageStrategy)
{
public:
	alias InMarshalStrategy!(StorageStrategy) MarshalStrategy;

	final string ToString()
	{
		return to!string(m_storer.GetBuffer().idup);
	}
	
	final auto GetBuffer()
	{
		return m_storer.GetBuffer().idup;
	}
	
	void Marshal(T)(T val, string name)
	{
		m_marshaller.Marshal(val, name);
	}
	
	this()
	{
		m_storer = new StorageStrategy;
		m_marshaller = new MarshalStrategy(m_storer);
		m_marshaller.BeginDocumentMarshal("");
	}
	
	private:
	StorageStrategy m_storer;
	MarshalStrategy m_marshaller;
}

mixin template MarshalMixinTemplate(StorageStrategy)
{
	void MarshalClassOrStruct(T)(T val, string name)
	{
		static if (__traits(hasMember, T, "BeginObjectMarshal") && __traits(hasMember, T, "EndObjectMarshal")
				&& (isSomeFunction!(T.BeginObjectMarshal!(typeof(this), StorageStrategy)) 
				&& (is(TemplateArgsOf!(T.BeginObjectMarshal!(typeof(this), StorageStrategy))[0] == typeof(this))
				&&  is(TemplateArgsOf!(T.BeginObjectMarshal!(typeof(this), StorageStrategy))[1] == StorageStrategy)))
				&& (isSomeFunction!(T.EndObjectMarshal!(typeof(this), StorageStrategy)) 
				&& (is(TemplateArgsOf!(T.EndObjectMarshal!(typeof(this), StorageStrategy))[0] == typeof(this))
				&&  is(TemplateArgsOf!(T.EndObjectMarshal!(typeof(this), StorageStrategy))[1] == StorageStrategy))))
		{
			val.BeginObjectMarshal!(typeof(this), StorageStrategy)(m_storer, name);
			foreach (item; __traits(allMembers, T))
			{
				static if (__traits(compiles, Marshal(__traits(getMember, val, item), item))
					&& !isSomeFunction!(typeof(__traits(getMember, val, item))))
				{
					Marshal(__traits(getMember, val, item), item);
				}
			}
			val.EndObjectMarshal!(typeof(this), StorageStrategy)(m_storer, name);
		}
		else 
		{
			BeginObjectMarshal(val, name);
			foreach (item; __traits(allMembers, T))
			{
				static if (__traits(compiles, Marshal(__traits(getMember, val, item), item))
					&& !isSomeFunction!(typeof(__traits(getMember, val, item))))
				{
					Marshal(__traits(getMember, val, item), item);
				}
			}
			EndObjectMarshal(val, name);
		}
	}
	
	void MarshalArray(T)(T val, string name)
	{
		static if (__traits(hasMember, T, "BeginArrayMarshal") && __traits(hasMember, T, "EndArrayMarshal")
				&& (isSomeFunction!(T.BeginArrayMarshal!(typeof(this), StorageStrategy)) 
				&& (is(TemplateArgsOf!(T.BeginArrayMarshal!(typeof(this), StorageStrategy))[0] == typeof(this))
				&&  is(TemplateArgsOf!(T.BeginArrayMarshal!(typeof(this), StorageStrategy))[1] == StorageStrategy)))
				&& (isSomeFunction!(T.EndArrayMarshal!(typeof(this), StorageStrategy)) 
				&& (is(TemplateArgsOf!(T.EndArrayMarshal!(typeof(this), StorageStrategy))[0] == typeof(this))
				&&  is(TemplateArgsOf!(T.EndArrayMarshal!(typeof(this), StorageStrategy))[1] == StorageStrategy))))
		{
			val.BeginArrayMarshal!(typeof(this), StorageStrategy)(storer, name);
			foreach (i, item; val)
			{
				Marshal(item, to!string(i));
			}
			val.EndArrayMarshal!(typeof(this), StorageStrategy)(storer, name);
		}
		else 
		{
			BeginArrayMarshal(val, name);
			foreach (i, item; val)
			{
				Marshal(item, to!string(i));
			}
			EndArrayMarshal(val, name);
		}
	}
	
	void Marshal(T)(T val, string name)
	{
		static if (__traits(hasMember, T, "Marshal") 
					&& isSomeFunction!(T.Marshal!(typeof(this), StorageStrategy))
					&& (is(TemplateArgsOf!(T.Marshal!(typeof(this), StorageStrategy))[0] == typeof(this))
					&&  is(TemplateArgsOf!(T.Marshal!(typeof(this), StorageStrategy))[1] == StorageStrategy)))
		{
			val.Marshal!(typeof(this), StorageStrategy)(m_storer, name);
		}
		else static if (is(T == struct) || is(T == class))
		{
			MarshalClassOrStruct(val, name);
		}
		else static if (isArray!(T) && !isSomeString!(T))
		{
			MarshalArray(val, name);
		}
		else static if (is(T == enum))
		{
			MarshalEnum(val, name);
		}
		else static if (is(T == union))
		{
			MarshalUnion(val, name);
		}
		else static if (__traits(isPOD, T))
		{
			//Any other POD, we've already covered structs
			MarshalSingleVar(val, name);
		}
		else 
		{
			//do nothing...
		}
	}
	
	private StorageStrategy m_storer;
	
	package this(StorageStrategy storer)
	{
		this.m_storer = storer; 
	}

}
