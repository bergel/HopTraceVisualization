Class {
	#name : #HTVFunctionCall,
	#superclass : #Object,
	#instVars : [
		'functionName',
		'numberOfExecutions',
		'outgoingCalls',
		'position'
	],
	#category : #HopTraceVisualization
}

{ #category : #accessing }
HTVFunctionCall >> functionName [
	^ functionName
]

{ #category : #accessing }
HTVFunctionCall >> functionName: anObject [
	functionName := anObject
]

{ #category : #initialization }
HTVFunctionCall >> initialize [

	super initialize.
	position := -1.
	functionName := 'anonymous'.
	outgoingCalls := OrderedCollection new.
	numberOfExecutions := 0.
]

{ #category : #accessing }
HTVFunctionCall >> numberOfExecutions [
	^ numberOfExecutions
]

{ #category : #accessing }
HTVFunctionCall >> numberOfExecutions: anInteger [
	self assert: [ anInteger isInteger ].
	numberOfExecutions := anInteger
]

{ #category : #accessing }
HTVFunctionCall >> outgoingCalls [
	^ outgoingCalls
]

{ #category : #accessing }
HTVFunctionCall >> outgoingCalls: anObject [
	outgoingCalls := anObject
]

{ #category : #accessing }
HTVFunctionCall >> position [
	^ position
]

{ #category : #accessing }
HTVFunctionCall >> position: anObject [
	position := anObject
]
