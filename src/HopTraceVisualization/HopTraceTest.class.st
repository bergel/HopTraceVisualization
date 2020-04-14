Class {
	#name : #HopTraceTest,
	#superclass : #TestCase,
	#category : #HopTraceVisualization
}

{ #category : #tests }
HopTraceTest >> testAccessingFunction [

	| m f |
	m := HTVModel new.
	m parseTraceJSONAsText: HopTraceExample new traceExample.
	
	f := m functionDefAtChar: 16325.
	self assert: f functionName equals: 'lq'.
	self assert: (m functionDefAtChar: 16327) equals: f.
	self assert: (m functionDefAtChar: 16459) equals: f.
	"self assert: (m functionDefAtChar: 16494) equals: f."
	
	f := m functionDefAtChar: 16544.
	self assert: f functionName equals: 'getSetRoot'.
	
	"------"
	f := m functionDefAtChar: 215.
	self assert: f functionName equals: 'Cons.prototype.toString'.
	self assert: f outgoingCalls isEmpty.
]

{ #category : #tests }
HopTraceTest >> testModel [

	| m |
	m := HTVModel new.
	m parseTraceJSONAsText: HopTraceExample new traceExample.
	self assert: m numberOfCalls equals: 133.
	self assert: m numberOfFunctionDefinitions equals: 51.
	
	m parseMemoryJSONAsText: HopTraceExample new memoryExample.
]

{ #category : #tests }
HopTraceTest >> testParseTrace [
 
	| v ds |
	v := (NeoJSONReader on: HopTraceExample new traceExample readStream) next.
	ds := (v at: 'calls') first at: 'calls'.
	self assert: ds size equals: 133.
	
]
