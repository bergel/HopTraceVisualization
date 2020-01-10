Class {
	#name : #HopTraceExample,
	#superclass : #Object,
	#category : #HopTraceVisualization
}

{ #category : #'as yet unclassified' }
HopTraceExample >> javaScriptExample [

	^ '-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----
"use strict";

// Adapted by Manuel Serrano from Olin Shivers''s maze.scm program
// Copyright (c) 1993 by Olin Shivers.
function Cons( car, cdr ) {
  this.car = car;
  this.cdr = cdr;
}

Cons.prototype.toString = function() {
  return "(" + this.car + (this.cdr instanceof Cons ? " " + this.cdr.toString() : "") + ")";
}

Cons.prototype.toConsString = function() {
  return "(" + this.car + " . " + this.cdr + ")";
}

function CONS( car, cdr ) {
  return new Cons( car, cdr );
}

function Harr( nrows, ncols, elts ) {
  this.nrows = nrows;
  this.ncols = ncols;
  this.elts = elts;
}

Harr.prototype.hrefRC = function( r, c ) {
  return this.elts[ this.ncols * r + c ];
}

Harr.prototype.href = function( x, y ) {
  let r = y / 2 >> 0;
  let c = x / 3 >> 0;

  return this.hrefRC( r, c );
}

function Wall( owner, neighbor, bit ) {
  this.owner = owner;       // Box that owns this wall.
  this.neighbor = neighbor; // The other box bordering this wall.
  this.bit = bit;           // a bit identifying this wall in OWNER''s box.
}

function Box( reachable, id, walls = -1, parent = false, mark = false ) {
  this.reachable = reachable; // Union/find set -- all reachable boxs.
  this.id = id;               // Identifying info (e.g., the coords of the box)
  this.walls = walls       // A bitset telling which walls are still standing. 
  this.parent = parent;    // For DFS spanning tree construction.
  this.mark = mark;        // For marking the solution path.
}

// Hex arrays
// Copyright (c) 1995 by Olin Shivers.

// External dependencies:
// - define-record

//        ___       ___       ___
//       /   \     /   \     /   \
//   ___/  A  \___/  A  \___/  A  \___
//  /   \     /   \     /   \     /   \
// /  A  \___/  A  \___/  A  \___/  A  \
// \     /   \     /   \     /   \     /
//  \___/     \___/     \___/     \___/
//  /   \     /   \     /   \     /   \
// /     \___/     \___/     \___/     \
// \     /   \     /   \     /   \     /
//  \___/     \___/     \___/     \___/
//  /   \     /   \     /   \     /   \
// /     \___/     \___/     \___/     \
// \     /   \     /   \     /   \     /
//  \___/     \___/     \___/     \___/

// Hex arrays are indexed by the (x,y) coord of the center of the hexagonal
// element. Hexes are three wide and two high; e.g., to get from the center
// of an elt to its {NW, N, NE} neighbors, add {(-3,1), (0,2), (3,1)}
// respectively.
//
// Hex arrays are represented with a matrix, essentially made by shoving the
// odd columns down a half-box so things line up. The mapping is as follows:
//     Center coord      row/column
//     ------------      ----------
//     (x,  y)        -> (y/2, x/3)
//     (3c, 2r + c&1) <- (r,   c)

function harrTabulate( nrows, ncols, proc ) {
  const v = new Array( nrows * ncols );

  for( let r = nrows - 1; !(r < 0); r-- ) {
     for( let c = 0, i = r * ncols; !(c === ncols); c++, i++ ) {
	 v[ i ] = proc( c * 3, 2 * r + (c & 1) );
     }
  }

  return new Harr( nrows, ncols, v );
}


// Hexagonal hackery for maze generation.
// Copyright (c) 1995 by Olin Shivers.

// Every elt of the hex array manages his SW, S, and SE wall.
// Terminology: - An even column is one whose column index is even. That
//                means the first, third, ... columns (indices 0, 2, ...).
//              - An odd column is one whose column index is odd. That
//                means the second, fourth... columns (indices 1, 3, ...).
//              The even/odd flip-flop is confusing; be careful to keep it
//              straight. The *even* columns are the low ones. The *odd*
//              columns are the high ones.
//    _   _
//  _/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/
//  0 1 2 3
const SOUTHWEST = 1;
const SOUTH = 2;
const SOUTHEAST = 4;

function genMazeArray( r, c ) {
  return harrTabulate( r, c, (x, y) => new Box( baseSet( 1 ), CONS( x, y ) ) );
}

// This could be made more efficient.
function makeWallVec( harr ) {
  let nrows = harr.nrows;
  let ncols = harr.ncols;
  let xmax = 3 * (ncols - 1);
  let walls = []; // Accumulate walls.

  function addWall( o, n, b ) { // owner neighbor bit
     walls.push( new Wall( o, n, b ) );
  }

  // Do everything but the bottom row.
  for( let x = 3 * (ncols - 1); !(x < 0); x -= 3 ) {
     for( let y = ((nrows - 1) * 2 ) + (x & 1); !(y <= 1); y -= 2 ) {
	 // don''t do bottom row.
	 let hex = harr.href( x, y );

	 if( x !== 0 ) addWall( hex, harr.href( x - 3, y - 1 ), SOUTHWEST );
	 addWall( hex, harr.href( x, y - 2 ), SOUTH );
	 if( x < xmax ) addWall( hex, harr.href( x + 3, y - 1 ), SOUTHEAST );
     }
  }

  // Do the SE and SW walls of the odd columns on the bottom row.
  // If the rightmost bottom hex lies in an odd column, however,
  // don''t add it''s SE wall -- it''s a corner hex, and has no SE neighbor.
  if( ncols > 1 ) {
     let rmocX = ~~(3 + (6 * ((ncols - 2) >> 1)));
     let rmocHex = harr.href( rmocX, 1 );

     if( rmocX < xmax ) { // Not a corner == do E wall.
	 addWall( rmocHex, harr.href( xmax, 0 ), SOUTHEAST );
     }
     addWall( rmocHex, harr.href( rmocX - 3, 0 ), SOUTHWEST );

     for( let x = rmocX - 6; !(x < 3); x -= 6 ) {
	 addWall( harr.href( x, 1 ), harr.href( x - 3, 0 ), SOUTHWEST );
	 addWall( harr.href( x, 1 ), harr.href( x + 3, 0 ), SOUTHEAST );
     }
  }

  return walls.reverse();
}

let TPLPres = {entrance: false, exit: false };
let BTLPres = { maxlen: false, trance: false, xit: false };

// Find the box ctop from the top row, and the box cbot from the bottom
// row such that cbot is furthest from ctop. 
// Return [ctop-x, ctop-y, cbot-x, cbot-y].
function pickEntrances( harr ) {
  let nrows = harr.nrows;
  let ncols = harr.ncols;

  dfsMaze( harr, harr.hrefRC( 0, 0 ), forEachHexChild );

  function TPLP( maxLen, entrance, exit, tcol ) {
/*       console.log( "TPLP maxlen=", maxLen, " entrance=", entrance, " exit=", exit, " tcol=", tcol ); */
     if( tcol < 0 ) {
	 TPLPres.entrance = entrance;
	 TPLPres.exit = exit;
	 
	 return TPLPres;
     } else {
	 let topBox = harr.hrefRC( nrows - 1, tcol );
	 rerootMaze( topBox );

	 function BTLP( maxLen, entrance, exit, bcol ) {
/* 	    console.log( "  BTLP maxlen=", maxLen, " entrance=", entrance, " exit=", exit, " bcol=", bcol ); */
	    if( bcol < 0 ) {
	       BTLPres.maxlen = maxLen;
	       BTLPres.trance = entrance;
	       BTLPres.xit = exit;
	       return BTLPres;
	    } else {
	       const thisLen = pathLength( harr.hrefRC( 0, bcol ) );

	       if( thisLen > maxLen ) {
		  return BTLP( thisLen, tcol, bcol, bcol - 1);
	       } else {
		  return BTLP( maxLen, entrance, exit, bcol - 1);
	       }
	    }
	 }

	 let { maxlen, trance, xit } =
	     BTLP( maxLen, entrance, exit, ncols - 1);

	 return TPLP( maxlen, trance, xit, tcol - 1);
     }
  }

  return TPLP( -1, false, false, ncols - 1);
}

// Apply PROC to each node reachable from BOX.
function forEachHexChild( proc, harr, box ) {
  const walls = box.walls;
  const id = box.id;
  const x = id.car;
  const y = id.cdr;
  const nr = harr.nrows;
  const nc = harr.ncols;
  const maxy = 2 * (nr - 1);
  const maxx = 3 * (nc - 1);

  if( !bitTest( walls, SOUTHWEST ) ) proc( harr.href( x - 3, y - 1 ) );
  if( !bitTest( walls, SOUTH ) ) proc( harr.href( x, y - 2 ) );
  if( !bitTest( walls, SOUTHEAST ) ) proc( harr.href( x + 3, y - 1 ) );

  // NW neighbor, if there is one (we may be in col 1, or top row/odd col)
  if( x > 0 // Not in first column.
      && (y <= maxy // Not on top row or
	   || (x % 6) === 0) ) { // Not in an odd column.
     let nw = harr.href( x - 3, y + 1 );
     if( !bitTest( nw.walls, SOUTHEAST ) ) proc( nw );
  }

  // N neighbor, if there is one (we may be on top row).
  if( y < maxy ) { // Not on top row
     let n = harr.href( x, y + 2 );
     if( !bitTest( n.walls, SOUTH ) ) proc( n );
  }

  // NE neighbor, if there is one (we may be in last col, or top row/odd col)
  if( x < maxx // ; Not in last column.
      && (y <= maxy // Not on top row or
	   || (x % 6) === 0) ) { // ; not in an odd column.
     let ne = harr.href( x + 3, y + 1 );
     if( !bitTest( ne.walls, SOUTHWEST ) ) proc( ne );
  }
}

// The top-level
function makeMaze( nrows, ncols ) {
  let boxs = genMazeArray( nrows, ncols );
  let walls = permuteVec( makeWallVec( boxs ), randomState( 20 ) );

  digMaze( walls, nrows * ncols );

  let { entrance, exit } = pickEntrances( boxs );

  let exitBox = boxs.hrefRC( 0, exit );
  let nwalls = exitBox.walls;

  rerootMaze( boxs.hrefRC( nrows - 1, entrance ) );
  markPath( exitBox );
  exitBox.walls = nwalls & ~SOUTH;

  return { boxs, entrance, exit };
}

function pmaze( nrows, ncols ) {
  let { boxs, entrance, exit } = makeMaze( nrows, ncols );

  printHexMaze( boxs, entrance );
}

// Print out a hex array with characters.
// Copyright (c) 1995 by Olin Shivers.

// External dependencies:
// - hex array code
// - hex box code

//    _   _
//  _/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ 

// Top part of top row looks like this:
//    _   _  _   _
//  _/ \_/ \/ \_/ \
// /
function printHexMaze( harr, entrance ) {
  let nrows = harr.nrows;
  let ncols = harr.ncols;
  let ncols2 = (ncols >> 1) << 1;

  // Print out the flat tops for the top row''s odd cols.
  for( let c = 1; !(c >= ncols); c+= 2 ) {
     display( "   " );
     writeChar( c === entrance ? " " : "_" );
  }
  newline();

  // Print out the slanted tops for the top row''s odd cols
  // and the flat tops for the top row''s even cols.
  writeChar( " " );
  for( let c = 0; !(c >= ncols2); c += 2 ) {
     display( c === entrance ? " " : "_" );
     display( "/" );
     display( dotSpace( harr, nrows - 1, c + 1 ) );
     display( "\\" );
  }

  if( ncols & 1 ) writeChar( entrance === (ncols - 1) ? " " : "_" );
  newline();

  for( let r = nrows - 1; !(r < 0); r-- ) {
     // Do the bottoms for row r''s odd cols.
     writeChar( "/" );
     for( let c = 1; !(c >= ncols2); c += 2 ) {
	 // The dot/space for the even col just behind c.
	 writeChar( dotSpace( harr, r, c - 1 ) );
	 displayHexBottom( harr.hrefRC( r, c ).walls );
     }

     if( ncols & 1 ) {
	 writeChar( dotSpace( harr, r, ncols - 1 ) );
	 writeChar( "\\" );
     }

     newline();

     // Do the bottoms for row r''s even cols.
     for( let c = 0; !(c >= ncols2); c += 2 ) {
	 displayHexBottom( harr.hrefRC( r, c ).walls );
	 // The dot/space is for the odd col just after c, on row below.
	 writeChar( dotSpace( harr, r - 1, c + 1 ) );
     }

     if( ncols & 1 ) {
	 displayHexBottom( harr.hrefRC( r, ncols - 1 ).walls );
     } else if( r !== 0 ) {
	 writeChar( "\\" );
     }

     newline();
  }
}

function bitTest( j, bit ) {
  return (j & bit) !== 0;
}

// Return a . if harr[r,c] is marked, otherwise a space.
// We use the dot to mark the solution path.
function dotSpace( harr, r, c ) {
  return ( r >= 0 && harr.hrefRC( r, c ).mark ) ? "." : " ";
}

// Print a \_/ hex bottom.
function displayHexBottom( hexwalls ) {
  writeChar( bitTest( hexwalls, SOUTHWEST ) ? "\\" : " " );
  writeChar( bitTest( hexwalls, SOUTH ) ? "_" : " " );
  writeChar( bitTest( hexwalls, SOUTHEAST ) ? "/" : " " );
}

//    _   _
//  _/ \_/ \
// / \_/ \_/
// \_/ \_/ \_/
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \
// / \_/ \_/
// \_/ \_/ \_/


// Randomly permute a vector.
function permuteVec( v, randomState ) {
  for( let i = v.length - 1; i > 1; i-- ) {
     let eli = v[ i ];
     let j = randomInt( i, randomState );

     v[ i ] = v[ j ];
     v[ j ] = eli;
  }

  return v;
}

Array.prototype.forEachRev = function( proc ) {
  for( let i = this.length - 1; i >= 0; i-- ) {
     proc( this[ i ] );
  }
}

// This is the core of the algorithm.
function digMaze( walls, nboxs ) {
  try {
     walls.forEachRev( wall => { // For each wall,
	 let c1 = wall.owner;     // find the boxs on
	 let set1 = c1.reachable;
	 let c2 = wall.neighbor; // each side of the wall
	 let set2 = c2.reachable;

	 // If there is no path from c1 to c2, knock down the
	 // wall and union the two sets of reachable boxs.
	 // If the new set of reachable boxs is the whole set
	 // of boxs, quit.
	 if( !setEqual( set1, set2 ) ) {
	    let nwalls = c1.walls;
	    let wallmask = ~wall.bit;
	    union( set1, set2 );

	    c1.walls = nwalls & wallmask;
	    if( setSize( set1 ) === nboxs ) {
	       throw false;
	    }
	 }
     } );
  } catch( exn ) {
     if( exn ) throw exn;
     ;
  }
}

// Some simple DFS routines useful for determining path length 
// through the maze.

// Build a DFS tree from ROOT. 
// (DO-CHILDREN proc maze node) applies PROC to each of NODE''s children.
// We assume there are no loops in the maze; if this is incorrect, the
// algorithm will diverge.
function dfsMaze( maze, root, doChildren ) {
  function search( node, parent ) {
     node.parent = parent;
     return doChildren( child => {
	 if( child !== parent ) search( child, node );
     }, maze, node );
  }

  return search( root, false );
}

// Move the root to NEW-ROOT
function rerootMaze( newRoot ) {
  function lp( node, newParent ) {
     let oldParent = node.parent;
     node.parent = newParent;
     if( oldParent ) lp( oldParent, node );
  }

  return lp( newRoot, false );
}

//  How far from BOX to the root?
function pathLength( box ) {
  let len = 0;
  let node = box.parent;

  for( ; !!node; len++, node = node.parent );

  return len;
}

// Mark the nodes from NODE back to root. Used to mark the winning path.
function markPath( node ) {
  node.mark = true;
  if( node.parent ) markPath( node.parent );
}

// Minimal Standard Random Number Generator
// Park & Miller, CACM 31(10), Oct 1988, 32 bit integer version.
// better constants, as proposed by Park.
// By Ozan Yigit

// Rehacked by Olin 4/1995.

function fx28( a ) {
  return ((1 << 28) - 1) & a;
}

// randomState
function *randomState( n ) {
  const A = 48271;
  const M = 268435455;
  const Q = 44488;
  const R = 3399;
  let seed = n;

  while( true ) {
     let hi = fx28( seed / Q );
     let lo = fx28( seed % Q );
     let test = fx28( fx28( A * lo ) - fx28( R * hi ) );
     let val = test > 0 ? test : fx28( test + M );

     yield val;
     seed = val;
  }
}

function rand( state ) {
  return state.next().value;
}

// rand

// randomInt
function randomInt( n, state ) {
  return fx28( rand( state ) % n );
}

// Tarjan''s amortised union-find data structure.
// Copyright (c) 1995 by Olin Shivers.

// This data structure implements disjoint sets of elements.
// Four operations are supported. The implementation is extremely
// fast -- any sequence of N operations can be performed in time
// so close to linear it''s laughable how close it is. See your
// intro data structures book for more. The operations are:
//
// - (base-set nelts) -> set
//   Returns a new set, of size NELTS.
//
// - (set-size s) -> integer
//   Returns the number of elements in set S.
//
// - (union! set1 set2)
//   Unions the two sets -- SET1 and SET2 are now considered the same set
//   by SET-EQUAL?.
//
// - (set-equal? set1 set2)
//   Returns true <==> the two sets are the same.

// Representation: a set is a cons box. Every set has a "representative"
// cons box, reached by chasing cdr links until we find the cons with
// cdr = (). Set equality is determined by comparing representatives using
// EQ?. A representative''s car contains the number of elements in the set.

// The speed of the algorithm comes because when we chase links to find 
// representatives, we collapse links by changing all the boxs in the path
// we followed to point directly to the representative, so that next time
// we walk the cdr-chain, we''ll go directly to the representative in one hop.
function baseSet( nelts ) {
  return CONS( nelts, null );
}

// Sets are chained together through cdr links. Last guy in the chain
// is the root of the set.
function getSetRoot( s ) {
  function lp( r ) { // Find the last pair
     let next = r.cdr; // in the list. That''s
     if( next ) { // the root r.
	 return lp( next );
     } else {
	 if( r !== s ) { // Now zip down the list again,
	    function lq( x ) {  // changing everyone''s cdr to r.
	       let next = x.cdr;
	       if( r !== next ) {
		  x.cdr = r;
		  return lq( next );
	       }
	    }

	    lq( s );
	 }

	 return r;
     }
  }

  return lp( s );
}

function setEqual( s1, s2 ) {
  return getSetRoot( s1 ) === getSetRoot( s2 );
}

function setSize( s ) {
  return getSetRoot( s ).car;
}

function union( s1, s2 ) {
  let r1 = getSetRoot( s1 );
  let r2 = getSetRoot( s2 );
  let n1 = setSize( r1 );
  let n2 = setSize( r2 );
  let n = n1 + n2;

  if( n1 > n2 ) {
     r2.cdr = r1;
     r1.car = n;
  } else {
     r1.cdr = r2;
     r2.car = n;
  }
}

var stdio = true;

function display( str ) {
  if( stdio != null ) {
     process.stdout.write( str );
  }
}

function writeChar( char ) {
  return display( char );
}

function newline() {
  return display( "\n" );
}

function main( bench, n ) {
  let res = 0;
  const k = Math.round( n / 10 );
  let i = 1;

  console.log( bench + "(", n, ")..." );

  stdio = null;
  while( n-- > 0 ) {
     if( n % k === 0 ) { console.log( i++ ); }
     pmaze( 100, 100 );
  }
  stdio = true;

  pmaze( 10, 35 );
}

const N = 
  (process.argv[ 1 ] === "fprofile") 
  ? 2
  : process.argv[ 2 ] ? parseInt( process.argv[ 2 ] ) : 200;

main( "maze", N ); '
]

{ #category : #running }
HopTraceExample >> run [
	<script: 'self new run inspect'>
	| m |
	m := HTVModel new.
	m parseTraceJSONAsText: HopTraceExample new traceExample.
	^ m
]

{ #category : #'as yet unclassified' }
HopTraceExample >> traceExample [

^ '{
"format": "memviz",
"version": "0.0.1",
"calls": [
 { "filename": "maze.js",
   "calls": [
     { "point": 791, "cnt": [ { "target": 617, "cnt": 81819 } ] },
     { "point": 3905, "cnt": 2, "target": 2724 },
     { "point": 4476, "cnt": [ { "target": 704, "cnt": 10215 } ] },
     { "point": 4510, "cnt": 10107, "target": 4165 },
     { "point": 4566, "cnt": 10215, "target": 4165 },
     { "point": 4629, "cnt": 10107, "target": 4165 },
     { "point": 5000, "cnt": [ { "target": 704, "cnt": 2 } ] },
     { "point": 5081, "cnt": 1, "target": 4165 },
     { "point": 5148, "cnt": 2, "target": 4165 },
     { "point": 5266, "cnt": 65, "target": 4165 },
     { "point": 5332, "cnt": 65, "target": 4165 },
     { "point": 5804, "cnt": 2, "target": 12928 },
     { "point": 6150, "cnt": [ { "target": 617, "cnt": 135 } ] },
     { "point": 6183, "cnt": 135, "target": 13216 },
     { "point": 6544, "cnt": 11225, "target": 13471 },
     { "point": 6621, "cnt": 23, "target": 6198 },
     { "point": 6687, "cnt": 11202, "target": 6198 },
     { "point": 6788, "cnt": 135, "target": 6198 },
     { "point": 6840, "cnt": 135, "target": 5856 },
     { "point": 6902, "cnt": 2, "target": 5856 },
     { "point": 7250, "cnt": 10350, "target": 10847 },
     { "point": 7277, "cnt": [ { "target": 13063, "cnt": 3486 } ] },
     { "point": 7323, "cnt": 10350, "target": 10847 },
     { "point": 7346, "cnt": [ { "target": 13063, "cnt": 3385 } ] },
     { "point": 7388, "cnt": 10350, "target": 10847 },
     { "point": 7415, "cnt": [ { "target": 13063, "cnt": 3477 } ] },
     { "point": 7677, "cnt": [ { "target": 704, "cnt": 10173 } ] },
     { "point": 7713, "cnt": 10173, "target": 10847 },
     { "point": 7743, "cnt": [ { "target": 13063, "cnt": 3477 } ] },
     { "point": 7876, "cnt": [ { "target": 704, "cnt": 10215 } ] },
     { "point": 7908, "cnt": 10215, "target": 10847 },
     { "point": 7933, "cnt": [ { "target": 13063, "cnt": 3385 } ] },
     { "point": 8185, "cnt": [ { "target": 704, "cnt": 10174 } ] },
     { "point": 8221, "cnt": 10174, "target": 10847 },
     { "point": 8251, "cnt": [ { "target": 13063, "cnt": 3486 } ] },
     { "point": 8346, "cnt": 2, "target": 3851 },
     { "point": 8389, "cnt": 2, "target": 11519 },
     { "point": 8444, "cnt": 2, "target": 11908 },
     { "point": 8512, "cnt": 2, "target": 5703 },
     { "point": 8551, "cnt": [ { "target": 617, "cnt": 2 } ] },
     { "point": 8609, "cnt": 2, "target": 13216 },
     { "point": 8660, "cnt": 2, "target": 13682 },
     { "point": 8824, "cnt": 2, "target": 8284 },
     { "point": 8858, "cnt": 2, "target": 9241 },
     { "point": 9488, "cnt": 67, "target": 16988 },
     { "point": 9514, "cnt": 67, "target": 17082 },
     { "point": 9561, "cnt": 2, "target": 17141 },
     { "point": 9691, "cnt": 2, "target": 17082 },
     { "point": 9759, "cnt": 67, "target": 16988 },
     { "point": 9804, "cnt": 67, "target": 16988 },
     { "point": 9826, "cnt": 67, "target": 16988 },
     { "point": 9879, "cnt": 67, "target": 16988 },
     { "point": 9923, "cnt": 1, "target": 17082 },
     { "point": 9975, "cnt": 2, "target": 17141 },
     { "point": 10086, "cnt": 110, "target": 17082 },
     { "point": 10206, "cnt": 5170, "target": 17082 },
     { "point": 10256, "cnt": 5170, "target": 11134 },
     { "point": 10331, "cnt": 10, "target": 17082 },
     { "point": 10378, "cnt": 10, "target": 17082 },
     { "point": 10410, "cnt": 110, "target": 17141 },
     { "point": 10529, "cnt": 5170, "target": 11134 },
     { "point": 10637, "cnt": 5170, "target": 17082 },
     { "point": 10724, "cnt": 10, "target": 11134 },
     { "point": 10803, "cnt": 99, "target": 17082 },
     { "point": 10835, "cnt": 110, "target": 17141 },
     { "point": 11075, "cnt": [ { "target": 617, "cnt": 10350 } ] },
     { "point": 11186, "cnt": 10350, "target": 17082 },
     { "point": 11247, "cnt": 10350, "target": 17082 },
     { "point": 11303, "cnt": 10350, "target": 17082 },
     { "point": 11651, "cnt": 30558, "target": 14500 },
     { "point": 11844, "cnt": [ { "target": 11976, "cnt": 28136 } ] },
     { "point": 11974, "cnt": [ { "target": 11766, "cnt": 2 } ] },
     { "point": 13167, "cnt": 2, "target": 12976 },
     { "point": 13375, "cnt": 2164, "target": 13252 },
     { "point": 13414, "cnt": 137, "target": 13252 },
     { "point": 13760, "cnt": 691, "target": 13682 },
     { "point": 14216, "cnt": 30558, "target": 13978 },
     { "point": 14249, "cnt": 30558, "target": 13978 },
     { "point": 14284, "cnt": 30558, "target": 13978 },
     { "point": 14547, "cnt": 30558, "target": 13978 },
     { "point": 15965, "cnt": 10350, "target": 422 },
     { "point": 16245, "cnt": 74288, "target": 13252 },
     { "point": 16459, "cnt": 13306, "target": 16325 },
     { "point": 16494, "cnt": 60982, "target": 16325 },
     { "point": 16544, "cnt": 108012, "target": 13252 },
     { "point": 16604, "cnt": 28136, "target": 16082 },
     { "point": 16625, "cnt": 28136, "target": 16082 },
     { "point": 16680, "cnt": 31044, "target": 16082 },
     { "point": 16743, "cnt": 10348, "target": 16082 },
     { "point": 16773, "cnt": 10348, "target": 16082 },
     { "point": 16800, "cnt": 10348, "target": 16636 },
     { "point": 16827, "cnt": 10348, "target": 16636 },
     { "point": 17128, "cnt": 41689, "target": 16988 },
     { "point": 17179, "cnt": 224, "target": 16988 },
     { "point": 17433, "cnt": 1, "target": 8749 },
     { "point": 17478, "cnt": 1, "target": 8749 },
     { "point": 17617, "cnt": 1, "target": 17192 } ] }
],
"symbols": [
 { "point": 215, "type": "fun", "name": "Cons.prototype.toString", "endpoint": 322 },
 { "point": 355, "type": "fun", "name": "Cons.prototype.toConsString", "endpoint": 419 },
 { "point": 422, "type": "fun", "name": "CONS", "endpoint": 482 },
 { "point": 485, "type": "fun", "name": "Harr", "endpoint": 590 },
 { "point": 617, "type": "fun", "name": "Harr.prototype.hrefRC", "endpoint": 679 },
 { "point": 704, "type": "fun", "name": "Harr.prototype.href", "endpoint": 801 },
 { "point": 804, "type": "fun", "name": "Wall", "endpoint": 1044 },
 { "point": 1047, "type": "fun", "name": "Box", "endpoint": 1484 },
 { "point": 2724, "type": "fun", "name": "harrTabulate", "endpoint": 3019 },
 { "point": 3851, "type": "fun", "name": "genMazeArray", "endpoint": 3964 },
 { "point": 3913, "type": "fun", "name": "anonymous", "endpoint": 3960 },
 { "point": 4005, "type": "fun", "name": "makeWallVec", "endpoint": 5430 },
 { "point": 4165, "type": "fun", "name": "addWall", "endpoint": 4261 },
 { "point": 5703, "type": "fun", "name": "pickEntrances", "endpoint": 6934 },
 { "point": 5856, "type": "fun", "name": "TPLP", "endpoint": 6885 },
 { "point": 6198, "type": "fun", "name": "BTLP", "endpoint": 6743 },
 { "point": 6984, "type": "fun", "name": "forEachHexChild", "endpoint": 8264 },
 { "point": 8284, "type": "fun", "name": "makeMaze", "endpoint": 8746 },
 { "point": 8749, "type": "fun", "name": "pmaze", "endpoint": 8878 },
 { "point": 9241, "type": "fun", "name": "printHexMaze", "endpoint": 10844 },
 { "point": 10847, "type": "fun", "name": "bitTest", "endpoint": 10903 },
 { "point": 11008, "type": "fun", "name": "dotSpace", "endpoint": 11104 },
 { "point": 11134, "type": "fun", "name": "displayHexBottom", "endpoint": 11351 },
 { "point": 11519, "type": "fun", "name": "permuteVec", "endpoint": 11567 },
 { "point": 11766, "type": "fun", "name": "Array.prototype.forEachRev", "endpoint": 11793 },
 { "point": 11908, "type": "fun", "name": "digMaze", "endpoint": 12636 },
 { "point": 11976, "type": "fun", "name": "anonymous", "endpoint": 12571 },
 { "point": 12928, "type": "fun", "name": "dfsMaze", "endpoint": 13184 },
 { "point": 12976, "type": "fun", "name": "search", "endpoint": 13148 },
 { "point": 13063, "type": "fun", "name": "anonymous", "endpoint": 13128 },
 { "point": 13216, "type": "fun", "name": "rerootMaze", "endpoint": 13434 },
 { "point": 13252, "type": "fun", "name": "lp", "endpoint": 13399 },
 { "point": 13471, "type": "fun", "name": "pathLength", "endpoint": 13606 },
 { "point": 13682, "type": "fun", "name": "markPath", "endpoint": 13777 },
 { "point": 13978, "type": "fun", "name": "fx28", "endpoint": 14030 },
 { "point": 14048, "type": "fun", "name": "randomState", "endpoint": 14075 },
 { "point": 14181, "type": "fun", "name": "anonymous", "endpoint": 14181 },
 { "point": 14181, "type": "fun", "name": "anonymous", "endpoint": 14181 },
 { "point": 14417, "type": "fun", "name": "rand", "endpoint": 14472 },
 { "point": 14500, "type": "fun", "name": "randomInt", "endpoint": 14570 },
 { "point": 15923, "type": "fun", "name": "baseSet", "endpoint": 15982 },
 { "point": 16082, "type": "fun", "name": "getSetRoot", "endpoint": 16551 },
 { "point": 16112, "type": "fun", "name": "lp", "endpoint": 16529 },
 { "point": 16325, "type": "fun", "name": "lq", "endpoint": 16484 },
 { "point": 16554, "type": "fun", "name": "setEqual", "endpoint": 16633 },
 { "point": 16636, "type": "fun", "name": "setSize", "endpoint": 16691 },
 { "point": 16694, "type": "fun", "name": "union", "endpoint": 16966 },
 { "point": 16988, "type": "fun", "name": "display", "endpoint": 17079 },
 { "point": 17082, "type": "fun", "name": "writeChar", "endpoint": 17138 },
 { "point": 17141, "type": "fun", "name": "newline", "endpoint": 17189 },
 { "point": 17192, "type": "fun", "name": "main", "endpoint": 17490 }
],
"config": {
 "hash": 53978075563705,
 "tmp": "/tmp/serrano/J2S/maze.js",
 "optim-tyflow": true,
 "optim-uninit": true,
 "optim-inline": true,
 "optim-callapply": true,
 "optim-clevel": true,
 "optim-multivar": true,
 "optim-cinstanceof": true,
 "optim-tyflow-resolve": true,
 "optim-unletrec": true,
 "optim-letopt": true,
 "optim-method": true,
 "optim-vector": true,
 "optim-ctor": true,
 "optim-range": true,
 "optim-hintnum": true,
 "optim-hint": true,
 "optim-array": true,
 "optim-literals": true,
 "optim-procedure": true,
 "optim-arguments": true,
 "optim-loopspec": true,
 "optim-globprop": true,
 "optim-inline-method": true,
 "optim-integer": true,
 "commonjs-export": true,
 "return-as-exit": false,
 "filename": "maze.js",
 "driver-name": "j2s-optim-driver",
 "worker": true,
 "worker-slave": false,
 "module-main": true,
 "module-name": "maze",
 "module-path": false,
 "hopscript-header": true,
 "type-annotations": false,
 "optim": 1000,
 "verbose": 0,
 "long-size": 64,
 "int-size": 61,
 "plugins-loader": false,
 "libs-dir": false,
 "debug": 0,
 "function-nice-name": true,
 "profile-symtable": true,
 "profile-call": true,
 "optim-ccall": true,
 "es6-let": true,
 "es6-const": true,
 "es6-arrow-function": true,
 "es6-default-value": true,
 "es6-rest-argument": true,
 "es2017-async": true,
 "debug": 0,
 "debug-client": 0
},
"run": {
 "commandline": "./a.out - 1",
 "date": "Wed Jan  8 11:16:27 2020"
 }
}'
]

{ #category : #'as yet unclassified' }
HopTraceExample >> traceMemoryExample [

^ '{"monitor":
 { "info": { "exec": "./a.out", "version": "0.0.3", "sizeWord": 1 } },
 { "gc": [
   { "number": 0, "alloc": 4497507, "heap": 4325376, "live": 2408496, "lastfun": ""unknown"", "time": 1578645572645914000 },
   { "number": 1, "alloc": 4621687, "heap": 7827456, "live": 5427104, "lastfun": ""&pthread-1036", "time": 1578645572678897000 },
   { "number": 2, "alloc": 7052727, "heap": 13922304, "live": 10759168, "lastfun": "{ "point": 804, "file": "maze.js" }", "time": 1578645572766804000 },
   { "number": 3, "alloc": 12025576, "heap": 24760320, "live": 11677376, "lastfun": "{ "point": 16082, "file": "maze.js" }", "time": 1578645573038010000 },
   { "number": 4, "alloc": 11351248, "heap": 24760320, "live": 11861120, "lastfun": "{ "point": 12976, "file": "maze.js" }", "time": 1578645576876914000 },
   { "number": 5, "alloc": 7977576, "heap": 24760320, "live": 6728320, "lastfun": ""&pthread-1036", "time": 1578645577800489000 }]}
 { "function": [
  { "function": "<@display<@maze,js:15614>:main@maze, "allocs": [
     { "gc": 5, "dsize": 2982816, "isize": 0
       { "dtype": [
           { "type": 334, "cnt": 7730, "size": 469984 },
           { "type": 3, "cnt": 9277, "size": 531872 },
           { "type": 13, "cnt": 18552, "size": 148416 },
           { "type": 30, "cnt": 9277, "size": 1026592 },
           { "type": 2, "cnt": 9280, "size": 259840 },
           { "type": 0, "cnt": 34132, "size": 546112 }] }
       { "itype": [] }}] },
  { "function": "<@displayHexBottom<@4846>:main@maze, "allocs": [
     { "gc": 5, "dsize": 993600, "isize": 2521312
       { "dtype": [
           { "type": 26, "cnt": 62100, "size": 993600 }] }
       { "itype": [
           { "type": 334, "cnt": 5250, "size": 319200 },
           { "type": 3, "cnt": 6300, "size": 361200 },
           { "type": 13, "cnt": 12600, "size": 100800 },
           { "type": 30, "cnt": 6300, "size": 697200 },
           { "type": 2, "cnt": 6304, "size": 176512 },
           { "type": 0, "cnt": 23100, "size": 369600 },
           { "type": 26, "cnt": 31050, "size": 496800 }] }}] },
  { "function": "for@maze.js:9983, "allocs": [
     { "gc": 5, "dsize": 669568, "isize": 4603984
       { "dtype": [
           { "type": 0, "cnt": 12, "size": 192 },
           { "type": 26, "cnt": 41836, "size": 669376 }] }
       { "itype": [
           { "type": 334, "cnt": 7200, "size": 437760 },
           { "type": 3, "cnt": 8640, "size": 495360 },
           { "type": 13, "cnt": 17280, "size": 138240 },
           { "type": 30, "cnt": 8640, "size": 956160 },
           { "type": 2, "cnt": 8644, "size": 242032 },
           { "type": 0, "cnt": 31680, "size": 506880 },
           { "type": 26, "cnt": 114222, "size": 1827552 }] }}] },
  { "function": { "point": 11008, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 165648, "isize": 0
       { "dtype": [
           { "type": 26, "cnt": 10349, "size": 165584 },
           { "type": 0, "cnt": 4, "size": 64 }] }
       { "itype": [] }}] },
  { "function": "for@maze.js:9703, "allocs": [
     { "gc": 5, "dsize": 5360, "isize": 132224
       { "dtype": [
           { "type": 26, "cnt": 335, "size": 5360 }] }
       { "itype": [
           { "type": 334, "cnt": 340, "size": 20672 },
           { "type": 3, "cnt": 408, "size": 23392 },
           { "type": 13, "cnt": 816, "size": 6528 },
           { "type": 30, "cnt": 408, "size": 45152 },
           { "type": 2, "cnt": 408, "size": 11424 },
           { "type": 26, "cnt": 66, "size": 1056 },
           { "type": 0, "cnt": 1500, "size": 24000 }] }}] },
  { "function": "<@newline<@maze,js:15655>:main@maze, "allocs": [
     { "gc": 5, "dsize": 3584, "isize": 42416
       { "dtype": [
           { "type": 26, "cnt": 224, "size": 3584 }] }
       { "itype": [
           { "type": 334, "cnt": 110, "size": 6688 },
           { "type": 3, "cnt": 132, "size": 7568 },
           { "type": 13, "cnt": 264, "size": 2112 },
           { "type": 30, "cnt": 132, "size": 14608 },
           { "type": 2, "cnt": 132, "size": 3696 },
           { "type": 0, "cnt": 484, "size": 7744 }] }}] },
  { "function": "<@writeChar<@maze,js5654>:main@maze, "allocs": [
     { "gc": 5, "dsize": 667024, "isize": 2774504
       { "dtype": [
           { "type": 26, "cnt": 41689, "size": 667024 }] }
       { "itype": [
           { "type": 334, "cnt": 7195, "size": 437456 },
           { "type": 3, "cnt": 8634, "size": 495016 },
           { "type": 13, "cnt": 17268, "size": 138144 },
           { "type": 30, "cnt": 8634, "size": 955496 },
           { "type": 2, "cnt": 8638, "size": 241864 },
           { "type": 0, "cnt": 31658, "size": 506528 }] }}] },
  { "function": "<@printHexMaze<@maze4843>:main@maze, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 5489856
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 7730, "size": 469984 },
           { "type": 3, "cnt": 9277, "size": 531872 },
           { "type": 13, "cnt": 18552, "size": 148416 },
           { "type": 30, "cnt": 9277, "size": 1026592 },
           { "type": 2, "cnt": 9280, "size": 259840 },
           { "type": 0, "cnt": 34148, "size": 546368 },
           { "type": 26, "cnt": 156674, "size": 2506784 }] }}] },
  { "function": "<@printHexMaze%%OI<@2322>:main@maze, "allocs": [
     { "gc": 5, "dsize": 112, "isize": 5489744
       { "dtype": [
           { "type": 26, "cnt": 7, "size": 112 }] }
       { "itype": [
           { "type": 334, "cnt": 7730, "size": 469984 },
           { "type": 3, "cnt": 9277, "size": 531872 },
           { "type": 13, "cnt": 18552, "size": 148416 },
           { "type": 30, "cnt": 9277, "size": 1026592 },
           { "type": 2, "cnt": 9280, "size": 259840 },
           { "type": 0, "cnt": 34148, "size": 546368 },
           { "type": 26, "cnt": 156667, "size": 2506672 }] }}] },
  { "function": "for@maze.js:9434, "allocs": [
     { "gc": 5, "dsize": 2144, "isize": 68640
       { "dtype": [
           { "type": 26, "cnt": 134, "size": 2144 }] }
       { "itype": [
           { "type": 334, "cnt": 170, "size": 10336 },
           { "type": 3, "cnt": 205, "size": 11744 },
           { "type": 13, "cnt": 408, "size": 3264 },
           { "type": 30, "cnt": 205, "size": 22624 },
           { "type": 2, "cnt": 204, "size": 5712 },
           { "type": 0, "cnt": 868, "size": 13888 },
           { "type": 26, "cnt": 67, "size": 1072 }] }}] },
  { "function": "<@markPath<@maze,js:5263>:main@maze, "allocs": [
     { "gc": 5, "dsize": 11056, "isize": 0
       { "dtype": [
           { "type": 26, "cnt": 691, "size": 11056 }] }
       { "itype": [] }}] },
  { "function": { "point": 6198, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 538848, "isize": 0
       { "dtype": [
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 26, "cnt": 33674, "size": 538784 }] }
       { "itype": [] }}] },
  { "function": { "point": 13252, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 34624, "isize": 0
       { "dtype": [
           { "type": 26, "cnt": 2164, "size": 34624 }] }
       { "itype": [] }}] },
  { "function": { "point": 13216, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 2192, "isize": 34624
       { "dtype": [
           { "type": 26, "cnt": 137, "size": 2192 }] }
       { "itype": [
           { "type": 26, "cnt": 2164, "size": 34624 }] }}] },
  { "function": { "point": 5856, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 8688, "isize": 568848
       { "dtype": [
           { "type": 26, "cnt": 539, "size": 8624 },
           { "type": 0, "cnt": 4, "size": 64 }] }
       { "itype": [
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 26, "cnt": 35549, "size": 568784 }] }}] },
  { "function": "maze.js:13063-1251:main@maze, "allocs": [
     { "gc": 5, "dsize": 29392, "isize": 1104176
       { "dtype": [
           { "type": 26, "cnt": 1837, "size": 29392 }] }
       { "itype": [
           { "type": 3, "cnt": 1837, "size": 146960 },
           { "type": 26, "cnt": 32256, "size": 516096 },
           { "type": 334, "cnt": 1838, "size": 102928 },
           { "type": 30, "cnt": 1838, "size": 249968 },
           { "type": 2, "cnt": 1838, "size": 88224 }] }},
     { "gc": 4, "dsize": 136176, "isize": 4833328
       { "dtype": [
           { "type": 26, "cnt": 8511, "size": 136176 }] }
       { "itype": [
           { "type": 0, "cnt": 36, "size": 576 },
           { "type": 26, "cnt": 131842, "size": 2109472 },
           { "type": 334, "cnt": 8510, "size": 476560 },
           { "type": 30, "cnt": 8510, "size": 1157360 },
           { "type": 2, "cnt": 8510, "size": 408480 },
           { "type": 3, "cnt": 8511, "size": 680880 }] }}] },
  { "function": "<@forEachHexChild<@m4596>:main@maze, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 1133728
       { "dtype": [] }
       { "itype": [
           { "type": 3, "cnt": 1837, "size": 146960 },
           { "type": 26, "cnt": 34103, "size": 545648 },
           { "type": 334, "cnt": 1838, "size": 102928 },
           { "type": 30, "cnt": 1838, "size": 249968 },
           { "type": 2, "cnt": 1838, "size": 88224 }] }},
     { "gc": 4, "dsize": 0, "isize": 4969824
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 8510, "size": 476560 },
           { "type": 30, "cnt": 8510, "size": 1157360 },
           { "type": 2, "cnt": 8510, "size": 408480 },
           { "type": 3, "cnt": 8511, "size": 680880 },
           { "type": 0, "cnt": 48, "size": 768 },
           { "type": 26, "cnt": 140361, "size": 2245776 }] }}] },
  { "function": { "point": 6984, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 385328, "isize": 748400
       { "dtype": [
           { "type": 26, "cnt": 24083, "size": 385328 }] }
       { "itype": [
           { "type": 3, "cnt": 1837, "size": 146960 },
           { "type": 26, "cnt": 10020, "size": 160320 },
           { "type": 334, "cnt": 1838, "size": 102928 },
           { "type": 30, "cnt": 1838, "size": 249968 },
           { "type": 2, "cnt": 1838, "size": 88224 }] }},
     { "gc": 4, "dsize": 1586736, "isize": 3383088
       { "dtype": [
           { "type": 0, "cnt": 48, "size": 768 },
           { "type": 26, "cnt": 99123, "size": 1585968 }] }
       { "itype": [
           { "type": 334, "cnt": 8510, "size": 476560 },
           { "type": 30, "cnt": 8510, "size": 1157360 },
           { "type": 2, "cnt": 8510, "size": 408480 },
           { "type": 3, "cnt": 8511, "size": 680880 },
           { "type": 26, "cnt": 41238, "size": 659808 }] }}] },
  { "function": { "point": 12976, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 588400, "isize": 545648
       { "dtype": [
           { "type": 3, "cnt": 1838, "size": 147040 },
           { "type": 334, "cnt": 1839, "size": 102984 },
           { "type": 30, "cnt": 1839, "size": 250104 },
           { "type": 2, "cnt": 1839, "size": 88272 }] }
       { "itype": [
           { "type": 26, "cnt": 34103, "size": 545648 }] }},
     { "gc": 4, "dsize": 2723600, "isize": 2246544
       { "dtype": [
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 }] }
       { "itype": [
           { "type": 0, "cnt": 48, "size": 768 },
           { "type": 26, "cnt": 140361, "size": 2245776 }] }}] },
  { "function": { "point": 12928, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 16, "isize": 1134048
       { "dtype": [
           { "type": 26, "cnt": 1, "size": 16 }] }
       { "itype": [
           { "type": 3, "cnt": 1838, "size": 147040 },
           { "type": 26, "cnt": 34103, "size": 545648 },
           { "type": 334, "cnt": 1839, "size": 102984 },
           { "type": 30, "cnt": 1839, "size": 250104 },
           { "type": 2, "cnt": 1839, "size": 88272 }] }},
     { "gc": 4, "dsize": 16, "isize": 4970144
       { "dtype": [
           { "type": 26, "cnt": 1, "size": 16 }] }
       { "itype": [
           { "type": 0, "cnt": 48, "size": 768 },
           { "type": 26, "cnt": 140361, "size": 2245776 },
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 }] }}] },
  { "function": "<@pickEntrances<@maz4215>:main@maze, "allocs": [
     { "gc": 5, "dsize": 64, "isize": 1711600
       { "dtype": [
           { "type": 26, "cnt": 4, "size": 64 }] }
       { "itype": [
           { "type": 0, "cnt": 8, "size": 128 },
           { "type": 3, "cnt": 1838, "size": 147040 },
           { "type": 26, "cnt": 70192, "size": 1123072 },
           { "type": 334, "cnt": 1839, "size": 102984 },
           { "type": 30, "cnt": 1839, "size": 250104 },
           { "type": 2, "cnt": 1839, "size": 88272 }] }},
     { "gc": 4, "dsize": 80, "isize": 4970160
       { "dtype": [
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 26, "cnt": 1, "size": 16 }] }
       { "itype": [
           { "type": 0, "cnt": 48, "size": 768 },
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 },
           { "type": 26, "cnt": 140362, "size": 2245792 }] }}] },
  { "function": { "point": 16325, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 5568, "isize": 0
       { "dtype": [
           { "type": 26, "cnt": 348, "size": 5568 }] }
       { "itype": [] }},
     { "gc": 4, "dsize": 206784, "isize": 0
       { "dtype": [
           { "type": 26, "cnt": 12924, "size": 206784 }] }
       { "itype": [] }},
     { "gc": 3, "dsize": 544, "isize": 0
       { "dtype": [
           { "type": 26, "cnt": 34, "size": 544 }] }
       { "itype": [] }}] },
  { "function": { "point": 16112, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 54336, "isize": 5568
       { "dtype": [
           { "type": 26, "cnt": 3396, "size": 54336 }] }
       { "itype": [
           { "type": 26, "cnt": 348, "size": 5568 }] }},
     { "gc": 4, "dsize": 2015584, "isize": 206784
       { "dtype": [
           { "type": 26, "cnt": 125974, "size": 2015584 }] }
       { "itype": [
           { "type": 26, "cnt": 12924, "size": 206784 }] }},
     { "gc": 3, "dsize": 94400, "isize": 544
       { "dtype": [
           { "type": 26, "cnt": 5900, "size": 94400 }] }
       { "itype": [
           { "type": 26, "cnt": 34, "size": 544 }] }}] },
  { "function": "<@setSize<@maze,js:15434>:main@maze, "allocs": [
     { "gc": 5, "dsize": 16752, "isize": 28080
       { "dtype": [
           { "type": 26, "cnt": 1047, "size": 16752 }] }
       { "itype": [
           { "type": 26, "cnt": 1755, "size": 28080 }] }},
     { "gc": 4, "dsize": 372528, "isize": 626928
       { "dtype": [
           { "type": 26, "cnt": 23283, "size": 372528 }] }
       { "itype": [
           { "type": 26, "cnt": 39183, "size": 626928 }] }},
     { "gc": 3, "dsize": 107424, "isize": 174912
       { "dtype": [
           { "type": 26, "cnt": 6714, "size": 107424 }] }
       { "itype": [
           { "type": 26, "cnt": 10932, "size": 174912 }] }}] },
  { "function": "<@union<@maze,js:1665466>:main@maze, "allocs": [
     { "gc": 5, "dsize": 22336, "isize": 42144
       { "dtype": [
           { "type": 26, "cnt": 1396, "size": 22336 }] }
       { "itype": [
           { "type": 26, "cnt": 2634, "size": 42144 }] }},
     { "gc": 4, "dsize": 496704, "isize": 979808
       { "dtype": [
           { "type": 26, "cnt": 31044, "size": 496704 }] }
       { "itype": [
           { "type": 26, "cnt": 61238, "size": 979808 }] }},
     { "gc": 3, "dsize": 143232, "isize": 228320
       { "dtype": [
           { "type": 26, "cnt": 8952, "size": 143232 }] }
       { "itype": [
           { "type": 26, "cnt": 14270, "size": 228320 }] }}] },
  { "function": { "point": 16082, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 49744, "isize": 59904
       { "dtype": [
           { "type": 26, "cnt": 3109, "size": 49744 }] }
       { "itype": [
           { "type": 26, "cnt": 3744, "size": 59904 }] }},
     { "gc": 4, "dsize": 1427600, "isize": 2222368
       { "dtype": [
           { "type": 26, "cnt": 89225, "size": 1427600 }] }
       { "itype": [
           { "type": 26, "cnt": 138898, "size": 2222368 }] }},
     { "gc": 3, "dsize": 250848, "isize": 94944
       { "dtype": [
           { "type": 26, "cnt": 15678, "size": 250848 }] }
       { "itype": [
           { "type": 26, "cnt": 5934, "size": 94944 }] }}] },
  { "function": "<@setEqual<@maze,js:5433>:main@maze, "allocs": [
     { "gc": 5, "dsize": 21824, "isize": 61760
       { "dtype": [
           { "type": 26, "cnt": 1364, "size": 21824 }] }
       { "itype": [
           { "type": 26, "cnt": 3860, "size": 61760 }] }},
     { "gc": 4, "dsize": 806720, "isize": 2539936
       { "dtype": [
           { "type": 26, "cnt": 50420, "size": 806720 }] }
       { "itype": [
           { "type": 26, "cnt": 158746, "size": 2539936 }] }},
     { "gc": 3, "dsize": 71808, "isize": 85792
       { "dtype": [
           { "type": 26, "cnt": 4488, "size": 71808 }] }
       { "itype": [
           { "type": 26, "cnt": 5362, "size": 85792 }] }}] },
  { "function": "Array.prototype.forEachRev:main@maze, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 203552
       { "dtype": [] }
       { "itype": [
           { "type": 26, "cnt": 12722, "size": 203552 }] }},
     { "gc": 4, "dsize": 0, "isize": 6380992
       { "dtype": [] }
       { "itype": [
           { "type": 26, "cnt": 398812, "size": 6380992 }] }},
     { "gc": 3, "dsize": 0, "isize": 811728
       { "dtype": [] }
       { "itype": [
           { "type": 26, "cnt": 50729, "size": 811664 },
           { "type": 0, "cnt": 4, "size": 64 }] }}] },
  { "function": "for@maze.js:11788, "allocs": [
     { "gc": 5, "dsize": 32992, "isize": 170560
       { "dtype": [
           { "type": 26, "cnt": 2062, "size": 32992 }] }
       { "itype": [
           { "type": 26, "cnt": 10660, "size": 170560 }] }},
     { "gc": 4, "dsize": 1055072, "isize": 5325920
       { "dtype": [
           { "type": 26, "cnt": 65942, "size": 1055072 }] }
       { "itype": [
           { "type": 26, "cnt": 332870, "size": 5325920 }] }},
     { "gc": 3, "dsize": 143472, "isize": 668256
       { "dtype": [
           { "type": 26, "cnt": 8963, "size": 143408 },
           { "type": 0, "cnt": 4, "size": 64 }] }
       { "itype": [
           { "type": 26, "cnt": 41766, "size": 668256 }] }}] },
  { "function": "<@digMaze<@maze,js:14877>:main@maze, "allocs": [
     { "gc": 5, "dsize": 488, "isize": 203552
       { "dtype": [
           { "type": 334, "cnt": 1, "size": 56 },
           { "type": 30, "cnt": 1, "size": 136 },
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 26, "cnt": 1, "size": 16 },
           { "type": 0, "cnt": 2, "size": 32 },
           { "type": 3, "cnt": 3, "size": 184 },
           { "type": 13, "cnt": 2, "size": 16 }] }
       { "itype": [
           { "type": 26, "cnt": 12722, "size": 203552 }] }},
     { "gc": 4, "dsize": 0, "isize": 6380992
       { "dtype": [] }
       { "itype": [
           { "type": 26, "cnt": 398812, "size": 6380992 }] }},
     { "gc": 3, "dsize": 536, "isize": 811728
       { "dtype": [
           { "type": 334, "cnt": 1, "size": 56 },
           { "type": 30, "cnt": 1, "size": 136 },
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 0, "cnt": 6, "size": 96 },
           { "type": 3, "cnt": 3, "size": 184 },
           { "type": 13, "cnt": 2, "size": 16 }] }
       { "itype": [
           { "type": 26, "cnt": 50729, "size": 811664 },
           { "type": 0, "cnt": 4, "size": 64 }] }}] },
  { "function": "<anonymous:5391>:main@maze, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 268240
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 958, "size": 61312 },
           { "type": 3, "cnt": 958, "size": 99632 },
           { "type": 16, "cnt": 3832, "size": 30656 },
           { "type": 26, "cnt": 4790, "size": 76640 }] }},
     { "gc": 3, "dsize": 0, "isize": 8287440
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 29598, "size": 1894272 },
           { "type": 3, "cnt": 29598, "size": 3078192 },
           { "type": 16, "cnt": 118392, "size": 947136 },
           { "type": 26, "cnt": 147990, "size": 2367840 }] }}] },
  { "function": { "point": 14181, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 268240
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 958, "size": 61312 },
           { "type": 3, "cnt": 958, "size": 99632 },
           { "type": 16, "cnt": 3832, "size": 30656 },
           { "type": 26, "cnt": 4790, "size": 76640 }] }},
     { "gc": 3, "dsize": 0, "isize": 8287440
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 29598, "size": 1894272 },
           { "type": 3, "cnt": 29598, "size": 3078192 },
           { "type": 16, "cnt": 118392, "size": 947136 },
           { "type": 26, "cnt": 147990, "size": 2367840 }] }}] },
  { "function": { "point": 13978, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 15344, "isize": 0
       { "dtype": [
           { "type": 16, "cnt": 1918, "size": 15344 }] }
       { "itype": [] }},
     { "gc": 3, "dsize": 473584, "isize": 0
       { "dtype": [
           { "type": 16, "cnt": 59198, "size": 473584 }] }
       { "itype": [] }}] },
  { "function": { "point": 14181, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 253176, "isize": 15344
       { "dtype": [
           { "type": 334, "cnt": 959, "size": 61376 },
           { "type": 3, "cnt": 959, "size": 99736 },
           { "type": 16, "cnt": 1918, "size": 15344 },
           { "type": 26, "cnt": 4795, "size": 76720 }] }
       { "itype": [
           { "type": 16, "cnt": 1918, "size": 15344 }] }},
     { "gc": 3, "dsize": 7814136, "isize": 473584
       { "dtype": [
           { "type": 334, "cnt": 29599, "size": 1894336 },
           { "type": 3, "cnt": 29599, "size": 3078296 },
           { "type": 16, "cnt": 59198, "size": 473584 },
           { "type": 26, "cnt": 147995, "size": 2367920 }] }
       { "itype": [
           { "type": 16, "cnt": 59198, "size": 473584 }] }}] },
  { "function": { "point": 14417, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 268536
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 959, "size": 61376 },
           { "type": 3, "cnt": 959, "size": 99736 },
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 26, "cnt": 4795, "size": 76720 },
           { "type": 13, "cnt": 2, "size": 16 }] }},
     { "gc": 3, "dsize": 0, "isize": 8287736
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 29599, "size": 1894336 },
           { "type": 3, "cnt": 29599, "size": 3078296 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 26, "cnt": 147995, "size": 2367920 },
           { "type": 13, "cnt": 2, "size": 16 }] }}] },
  { "function": "<anonymous:5386>:main@maze, "allocs": [
     { "gc": 5, "dsize": 16, "isize": 280
       { "dtype": [
           { "type": 13, "cnt": 2, "size": 16 }] }
       { "itype": [
           { "type": 334, "cnt": 1, "size": 64 },
           { "type": 3, "cnt": 1, "size": 104 },
           { "type": 16, "cnt": 4, "size": 32 },
           { "type": 26, "cnt": 5, "size": 80 }] }},
     { "gc": 3, "dsize": 16, "isize": 280
       { "dtype": [
           { "type": 13, "cnt": 2, "size": 16 }] }
       { "itype": [
           { "type": 334, "cnt": 1, "size": 64 },
           { "type": 3, "cnt": 1, "size": 104 },
           { "type": 16, "cnt": 4, "size": 32 },
           { "type": 26, "cnt": 5, "size": 80 }] }}] },
  { "function": "<@randomInt<@maze,js5425>:main@maze, "allocs": [
     { "gc": 5, "dsize": 30688, "isize": 268536
       { "dtype": [
           { "type": 26, "cnt": 1918, "size": 30688 }] }
       { "itype": [
           { "type": 334, "cnt": 959, "size": 61376 },
           { "type": 3, "cnt": 959, "size": 99736 },
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 26, "cnt": 4795, "size": 76720 },
           { "type": 13, "cnt": 2, "size": 16 }] }},
     { "gc": 3, "dsize": 947168, "isize": 8287736
       { "dtype": [
           { "type": 26, "cnt": 59198, "size": 947168 }] }
       { "itype": [
           { "type": 334, "cnt": 29599, "size": 1894336 },
           { "type": 3, "cnt": 29599, "size": 3078296 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 26, "cnt": 147995, "size": 2367920 },
           { "type": 13, "cnt": 2, "size": 16 }] }}] },
  { "function": "<@permuteVec<@maze,j4853>:main@maze, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 314568
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 959, "size": 61376 },
           { "type": 3, "cnt": 959, "size": 99736 },
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 26, "cnt": 7672, "size": 122752 }] }},
     { "gc": 3, "dsize": 0, "isize": 9708488
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 29599, "size": 1894336 },
           { "type": 3, "cnt": 29599, "size": 3078296 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 26, "cnt": 236792, "size": 3788672 }] }}] },
  { "function": "for@maze.js:11562, "allocs": [
     { "gc": 5, "dsize": 15344, "isize": 299224
       { "dtype": [
           { "type": 26, "cnt": 959, "size": 15344 }] }
       { "itype": [
           { "type": 334, "cnt": 959, "size": 61376 },
           { "type": 3, "cnt": 959, "size": 99736 },
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 26, "cnt": 6713, "size": 107408 }] }},
     { "gc": 3, "dsize": 473584, "isize": 9234904
       { "dtype": [
           { "type": 26, "cnt": 29599, "size": 473584 }] }
       { "itype": [
           { "type": 334, "cnt": 29599, "size": 1894336 },
           { "type": 3, "cnt": 29599, "size": 3078296 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 26, "cnt": 207193, "size": 3315088 }] }}] },
  { "function": "<@randomState<@maze,5383>:main@maze, "allocs": [
     { "gc": 5, "dsize": 128, "isize": 0
       { "dtype": [
           { "type": 30, "cnt": 1, "size": 48 },
           { "type": 3, "cnt": 1, "size": 64 },
           { "type": 13, "cnt": 2, "size": 16 }] }
       { "itype": [] }},
     { "gc": 3, "dsize": 128, "isize": 0
       { "dtype": [
           { "type": 30, "cnt": 1, "size": 48 },
           { "type": 3, "cnt": 1, "size": 64 },
           { "type": 13, "cnt": 2, "size": 16 }] }
       { "itype": [] }}] },
  { "function": "for@maze.js:5212, "allocs": [
     { "gc": 5, "dsize": 1536, "isize": 3328
       { "dtype": [
           { "type": 26, "cnt": 96, "size": 1536 }] }
       { "itype": [
           { "type": 334, "cnt": 32, "size": 2304 },
           { "type": 26, "cnt": 64, "size": 1024 }] }},
     { "gc": 3, "dsize": 4896, "isize": 10192
       { "dtype": [
           { "type": 0, "cnt": 16, "size": 256 },
           { "type": 26, "cnt": 290, "size": 4640 }] }
       { "itype": [
           { "type": 334, "cnt": 98, "size": 7056 },
           { "type": 26, "cnt": 196, "size": 3136 }] }}] },
  { "function": { "point": 4165, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 16384, "isize": 69192
       { "dtype": [
           { "type": 2, "cnt": 8, "size": 16384 }] }
       { "itype": [
           { "type": 334, "cnt": 961, "size": 69192 }] }},
     { "gc": 3, "dsize": 0, "isize": 827208
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 11489, "size": 827208 }] }},
     { "gc": 2, "dsize": 524328, "isize": 1305432
       { "dtype": [
           { "type": 2, "cnt": 13, "size": 524328 }] }
       { "itype": [
           { "type": 0, "cnt": 6, "size": 96 },
           { "type": 54, "cnt": 3, "size": 408 },
           { "type": 30, "cnt": 3, "size": 432 },
           { "type": 2, "cnt": 6, "size": 144 },
           { "type": 15, "cnt": 6, "size": 288 },
           { "type": 334, "cnt": 18112, "size": 1304064 }] }}] },
  { "function": { "point": 804, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 69192, "isize": 0
       { "dtype": [
           { "type": 334, "cnt": 961, "size": 69192 }] }
       { "itype": [] }},
     { "gc": 3, "dsize": 827208, "isize": 0
       { "dtype": [
           { "type": 334, "cnt": 11489, "size": 827208 }] }
       { "itype": [] }},
     { "gc": 2, "dsize": 1305432, "isize": 0
       { "dtype": [
           { "type": 0, "cnt": 6, "size": 96 },
           { "type": 54, "cnt": 3, "size": 408 },
           { "type": 30, "cnt": 3, "size": 432 },
           { "type": 2, "cnt": 6, "size": 144 },
           { "type": 15, "cnt": 6, "size": 288 },
           { "type": 334, "cnt": 18112, "size": 1304064 }] }
       { "itype": [] }}] },
  { "function": "Harr.prototype.href:main@maze, "allocs": [
     { "gc": 5, "dsize": 151872, "isize": 0
       { "dtype": [
           { "type": 26, "cnt": 9492, "size": 151872 }] }
       { "itype": [] }},
     { "gc": 4, "dsize": 523632, "isize": 0
       { "dtype": [
           { "type": 26, "cnt": 32727, "size": 523632 }] }
       { "itype": [] }},
     { "gc": 3, "dsize": 246672, "isize": 0
       { "dtype": [
           { "type": 26, "cnt": 15417, "size": 246672 }] }
       { "itype": [] }},
     { "gc": 2, "dsize": 386976, "isize": 0
       { "dtype": [
           { "type": 26, "cnt": 24182, "size": 386912 },
           { "type": 0, "cnt": 4, "size": 64 }] }
       { "itype": [] }}] },
  { "function": "for@maze.js:4307, "allocs": [
     { "gc": 5, "dsize": 34704, "isize": 103000
       { "dtype": [
           { "type": 26, "cnt": 2169, "size": 34704 }] }
       { "itype": [
           { "type": 2, "cnt": 8, "size": 16384 },
           { "type": 334, "cnt": 927, "size": 66744 },
           { "type": 26, "cnt": 1242, "size": 19872 }] }},
     { "gc": 3, "dsize": 425744, "isize": 1063584
       { "dtype": [
           { "type": 26, "cnt": 26609, "size": 425744 }] }
       { "itype": [
           { "type": 334, "cnt": 11390, "size": 820080 },
           { "type": 26, "cnt": 15219, "size": 243504 }] }},
     { "gc": 2, "dsize": 676912, "isize": 2216736
       { "dtype": [
           { "type": 26, "cnt": 42291, "size": 676656 },
           { "type": 0, "cnt": 16, "size": 256 }] }
       { "itype": [
           { "type": 54, "cnt": 3, "size": 408 },
           { "type": 30, "cnt": 3, "size": 432 },
           { "type": 2, "cnt": 19, "size": 524472 },
           { "type": 15, "cnt": 6, "size": 288 },
           { "type": 334, "cnt": 18112, "size": 1304064 },
           { "type": 26, "cnt": 24182, "size": 386912 },
           { "type": 0, "cnt": 10, "size": 160 }] }}] },
  { "function": "<@makeWallVec<@maze,3946>:main@maze, "allocs": [
     { "gc": 5, "dsize": 224, "isize": 142760
       { "dtype": [
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 26, "cnt": 4, "size": 64 },
           { "type": 336, "cnt": 1, "size": 96 }] }
       { "itype": [
           { "type": 2, "cnt": 8, "size": 16384 },
           { "type": 334, "cnt": 961, "size": 69192 },
           { "type": 26, "cnt": 3574, "size": 57184 }] }},
     { "gc": 3, "dsize": 144, "isize": 1504520
       { "dtype": [
           { "type": 26, "cnt": 1, "size": 16 },
           { "type": 0, "cnt": 8, "size": 128 }] }
       { "itype": [
           { "type": 0, "cnt": 16, "size": 256 },
           { "type": 334, "cnt": 11489, "size": 827208 },
           { "type": 26, "cnt": 42316, "size": 677056 }] }},
     { "gc": 2, "dsize": 96, "isize": 2893648
       { "dtype": [
           { "type": 336, "cnt": 1, "size": 96 }] }
       { "itype": [
           { "type": 54, "cnt": 3, "size": 408 },
           { "type": 30, "cnt": 3, "size": 432 },
           { "type": 2, "cnt": 19, "size": 524472 },
           { "type": 15, "cnt": 6, "size": 288 },
           { "type": 334, "cnt": 18112, "size": 1304064 },
           { "type": 26, "cnt": 66473, "size": 1063568 },
           { "type": 0, "cnt": 26, "size": 416 }] }}] },
  { "function": { "point": 485, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 72, "isize": 0
       { "dtype": [
           { "type": 334, "cnt": 1, "size": 72 }] }
       { "itype": [] }},
     { "gc": 2, "dsize": 1440, "isize": 0
       { "dtype": [
           { "type": 0, "cnt": 6, "size": 96 },
           { "type": 54, "cnt": 3, "size": 408 },
           { "type": 30, "cnt": 3, "size": 432 },
           { "type": 2, "cnt": 6, "size": 144 },
           { "type": 15, "cnt": 6, "size": 288 },
           { "type": 334, "cnt": 1, "size": 72 }] }
       { "itype": [] }}] },
  { "function": { "point": 1047, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 30800, "isize": 0
       { "dtype": [
           { "type": 334, "cnt": 350, "size": 30800 }] }
       { "itype": [] }},
     { "gc": 2, "dsize": 882360, "isize": 0
       { "dtype": [
           { "type": 0, "cnt": 10, "size": 160 },
           { "type": 54, "cnt": 5, "size": 680 },
           { "type": 30, "cnt": 5, "size": 720 },
           { "type": 2, "cnt": 10, "size": 320 },
           { "type": 15, "cnt": 10, "size": 480 },
           { "type": 334, "cnt": 10000, "size": 880000 }] }
       { "itype": [] }}] },
  { "function": "<@CONS<@maze,js:422@3384>:main@maze, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 44800
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 700, "size": 44800 }] }},
     { "gc": 2, "dsize": 0, "isize": 1280896
       { "dtype": [] }
       { "itype": [
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 54, "cnt": 2, "size": 272 },
           { "type": 30, "cnt": 2, "size": 288 },
           { "type": 2, "cnt": 4, "size": 80 },
           { "type": 15, "cnt": 4, "size": 192 },
           { "type": 334, "cnt": 20000, "size": 1280000 }] }}] },
  { "function": { "point": 120, "file": "maze.js" }, "allocs": [
     { "gc": 5, "dsize": 44800, "isize": 0
       { "dtype": [
           { "type": 334, "cnt": 700, "size": 44800 }] }
       { "itype": [] }},
     { "gc": 2, "dsize": 1280896, "isize": 0
       { "dtype": [
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 54, "cnt": 2, "size": 272 },
           { "type": 30, "cnt": 2, "size": 288 },
           { "type": 2, "cnt": 4, "size": 80 },
           { "type": 15, "cnt": 4, "size": 192 },
           { "type": 334, "cnt": 20000, "size": 1280000 }] }
       { "itype": [] }}] },
  { "function": "<@baseSet<@maze,js:15430>:main@maze, "allocs": [
     { "gc": 5, "dsize": 5600, "isize": 22400
       { "dtype": [
           { "type": 26, "cnt": 350, "size": 5600 }] }
       { "itype": [
           { "type": 334, "cnt": 350, "size": 22400 }] }},
     { "gc": 2, "dsize": 160000, "isize": 640896
       { "dtype": [
           { "type": 26, "cnt": 10000, "size": 160000 }] }
       { "itype": [
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 54, "cnt": 2, "size": 272 },
           { "type": 30, "cnt": 2, "size": 288 },
           { "type": 2, "cnt": 4, "size": 80 },
           { "type": 15, "cnt": 4, "size": 192 },
           { "type": 334, "cnt": 10000, "size": 640000 }] }}] },
  { "function": "for@maze.js:2815, "allocs": [
     { "gc": 5, "dsize": 11200, "isize": 81200
       { "dtype": [
           { "type": 26, "cnt": 700, "size": 11200 }] }
       { "itype": [
           { "type": 334, "cnt": 1050, "size": 75600 },
           { "type": 26, "cnt": 350, "size": 5600 }] }},
     { "gc": 2, "dsize": 320000, "isize": 2323256
       { "dtype": [
           { "type": 26, "cnt": 20000, "size": 320000 }] }
       { "itype": [
           { "type": 0, "cnt": 14, "size": 224 },
           { "type": 54, "cnt": 7, "size": 952 },
           { "type": 30, "cnt": 7, "size": 1008 },
           { "type": 2, "cnt": 14, "size": 400 },
           { "type": 15, "cnt": 14, "size": 672 },
           { "type": 334, "cnt": 30000, "size": 2160000 },
           { "type": 26, "cnt": 10000, "size": 160000 }] }}] },
  { "function": "<@harrTabulate<@maze3911>:main@maze, "allocs": [
     { "gc": 5, "dsize": 2864, "isize": 92472
       { "dtype": [
           { "type": 2, "cnt": 1, "size": 2808 },
           { "type": 30, "cnt": 1, "size": 56 }] }
       { "itype": [
           { "type": 334, "cnt": 1051, "size": 75672 },
           { "type": 26, "cnt": 1050, "size": 16800 }] }},
     { "gc": 2, "dsize": 80064, "isize": 2644696
       { "dtype": [
           { "type": 2, "cnt": 1, "size": 80008 },
           { "type": 30, "cnt": 1, "size": 56 }] }
       { "itype": [
           { "type": 0, "cnt": 20, "size": 320 },
           { "type": 54, "cnt": 10, "size": 1360 },
           { "type": 30, "cnt": 10, "size": 1440 },
           { "type": 2, "cnt": 20, "size": 544 },
           { "type": 15, "cnt": 20, "size": 960 },
           { "type": 334, "cnt": 30001, "size": 2160072 },
           { "type": 26, "cnt": 30000, "size": 480000 }] }}] },
  { "function": "<@genMazeArray<@maze3941>:main@maze, "allocs": [
     { "gc": 5, "dsize": 80, "isize": 95336
       { "dtype": [
           { "type": 3, "cnt": 1, "size": 64 },
           { "type": 26, "cnt": 1, "size": 16 }] }
       { "itype": [
           { "type": 334, "cnt": 1051, "size": 75672 },
           { "type": 26, "cnt": 1050, "size": 16800 },
           { "type": 2, "cnt": 1, "size": 2808 },
           { "type": 30, "cnt": 1, "size": 56 }] }},
     { "gc": 2, "dsize": 80, "isize": 2724760
       { "dtype": [
           { "type": 3, "cnt": 1, "size": 64 },
           { "type": 26, "cnt": 1, "size": 16 }] }
       { "itype": [
           { "type": 0, "cnt": 20, "size": 320 },
           { "type": 54, "cnt": 10, "size": 1360 },
           { "type": 15, "cnt": 20, "size": 960 },
           { "type": 334, "cnt": 30001, "size": 2160072 },
           { "type": 26, "cnt": 30000, "size": 480000 },
           { "type": 2, "cnt": 21, "size": 80552 },
           { "type": 30, "cnt": 11, "size": 1496 }] }}] },
  { "function": "<@makeMaze<@maze,js:4599>:main@maze, "allocs": [
     { "gc": 5, "dsize": 464, "isize": 2486672
       { "dtype": [
           { "type": 334, "cnt": 2, "size": 144 },
           { "type": 26, "cnt": 12, "size": 192 },
           { "type": 0, "cnt": 8, "size": 128 }] }
       { "itype": [
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 13, "cnt": 6, "size": 48 },
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 14, "size": 224 },
           { "type": 3, "cnt": 2802, "size": 247088 },
           { "type": 26, "cnt": 96337, "size": 1541392 },
           { "type": 334, "cnt": 4811, "size": 309280 },
           { "type": 30, "cnt": 1842, "size": 250344 },
           { "type": 2, "cnt": 1849, "size": 107512 }] }},
     { "gc": 4, "dsize": 16, "isize": 11351232
       { "dtype": [
           { "type": 26, "cnt": 1, "size": 16 }] }
       { "itype": [
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 },
           { "type": 0, "cnt": 52, "size": 832 },
           { "type": 26, "cnt": 539175, "size": 8626800 }] }},
     { "gc": 3, "dsize": 32, "isize": 12025544
       { "dtype": [
           { "type": 26, "cnt": 2, "size": 32 }] }
       { "itype": [
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 30, "cnt": 2, "size": 184 },
           { "type": 3, "cnt": 29603, "size": 3078544 },
           { "type": 13, "cnt": 6, "size": 48 },
           { "type": 0, "cnt": 34, "size": 544 },
           { "type": 334, "cnt": 41089, "size": 2721600 },
           { "type": 26, "cnt": 329838, "size": 5277408 }] }},
     { "gc": 2, "dsize": 48, "isize": 5618584
       { "dtype": [
           { "type": 26, "cnt": 3, "size": 48 }] }
       { "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 46, "size": 736 },
           { "type": 54, "cnt": 13, "size": 1768 },
           { "type": 15, "cnt": 26, "size": 1248 },
           { "type": 334, "cnt": 48113, "size": 3464136 },
           { "type": 2, "cnt": 40, "size": 605024 },
           { "type": 30, "cnt": 14, "size": 1928 },
           { "type": 3, "cnt": 1, "size": 64 },
           { "type": 26, "cnt": 96474, "size": 1543584 }] }}] },
  { "function": "<@pmaze<@maze,js:8744755>:main@maze, "allocs": [
     { "gc": 5, "dsize": 48, "isize": 7976992
       { "dtype": [
           { "type": 26, "cnt": 3, "size": 48 }] }
       { "itype": [
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 13, "cnt": 18558, "size": 148464 },
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 34170, "size": 546720 },
           { "type": 3, "cnt": 12079, "size": 778960 },
           { "type": 26, "cnt": 253023, "size": 4048368 },
           { "type": 334, "cnt": 12543, "size": 779408 },
           { "type": 30, "cnt": 11119, "size": 1276936 },
           { "type": 2, "cnt": 11129, "size": 367352 }] }},
     { "gc": 4, "dsize": 0, "isize": 11351248
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 },
           { "type": 0, "cnt": 52, "size": 832 },
           { "type": 26, "cnt": 539176, "size": 8626816 }] }},
     { "gc": 3, "dsize": 0, "isize": 12025576
       { "dtype": [] }
       { "itype": [
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 30, "cnt": 2, "size": 184 },
           { "type": 3, "cnt": 29603, "size": 3078544 },
           { "type": 13, "cnt": 6, "size": 48 },
           { "type": 0, "cnt": 34, "size": 544 },
           { "type": 334, "cnt": 41089, "size": 2721600 },
           { "type": 26, "cnt": 329840, "size": 5277440 }] }},
     { "gc": 2, "dsize": 16, "isize": 5618632
       { "dtype": [
           { "type": 26, "cnt": 1, "size": 16 }] }
       { "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 46, "size": 736 },
           { "type": 54, "cnt": 13, "size": 1768 },
           { "type": 15, "cnt": 26, "size": 1248 },
           { "type": 334, "cnt": 48113, "size": 3464136 },
           { "type": 2, "cnt": 40, "size": 605024 },
           { "type": 30, "cnt": 14, "size": 1928 },
           { "type": 3, "cnt": 1, "size": 64 },
           { "type": 26, "cnt": 96477, "size": 1543632 }] }}] },
  { "function": "while:maze.js, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 3879688
       { "dtype": [] }
       { "itype": [
           { "type": 0, "cnt": 28, "size": 448 },
           { "type": 3, "cnt": 1488, "size": 119040 },
           { "type": 26, "cnt": 212673, "size": 3402768 },
           { "type": 334, "cnt": 1490, "size": 83456 },
           { "type": 30, "cnt": 1489, "size": 202504 },
           { "type": 2, "cnt": 1489, "size": 71472 }] }},
     { "gc": 4, "dsize": 0, "isize": 11351248
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 },
           { "type": 0, "cnt": 52, "size": 832 },
           { "type": 26, "cnt": 539176, "size": 8626816 }] }},
     { "gc": 3, "dsize": 0, "isize": 12025576
       { "dtype": [] }
       { "itype": [
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 30, "cnt": 2, "size": 184 },
           { "type": 3, "cnt": 29603, "size": 3078544 },
           { "type": 13, "cnt": 6, "size": 48 },
           { "type": 0, "cnt": 34, "size": 544 },
           { "type": 334, "cnt": 41089, "size": 2721600 },
           { "type": 26, "cnt": 329840, "size": 5277440 }] }},
     { "gc": 2, "dsize": 16, "isize": 5618648
       { "dtype": [
           { "type": 26, "cnt": 1, "size": 16 }] }
       { "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 46, "size": 736 },
           { "type": 54, "cnt": 13, "size": 1768 },
           { "type": 15, "cnt": 26, "size": 1248 },
           { "type": 334, "cnt": 48113, "size": 3464136 },
           { "type": 2, "cnt": 40, "size": 605024 },
           { "type": 30, "cnt": 14, "size": 1928 },
           { "type": 3, "cnt": 1, "size": 64 },
           { "type": 26, "cnt": 96478, "size": 1543648 }] }}] },
  { "function": "<@main<@maze,js:17195657>:main@maze, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 7977056
       { "dtype": [] }
       { "itype": [
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 13, "cnt": 18558, "size": 148464 },
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 34170, "size": 546720 },
           { "type": 3, "cnt": 12079, "size": 778960 },
           { "type": 26, "cnt": 253027, "size": 4048432 },
           { "type": 334, "cnt": 12543, "size": 779408 },
           { "type": 30, "cnt": 11119, "size": 1276936 },
           { "type": 2, "cnt": 11129, "size": 367352 }] }},
     { "gc": 4, "dsize": 0, "isize": 11351248
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 },
           { "type": 0, "cnt": 52, "size": 832 },
           { "type": 26, "cnt": 539176, "size": 8626816 }] }},
     { "gc": 3, "dsize": 0, "isize": 12025576
       { "dtype": [] }
       { "itype": [
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 30, "cnt": 2, "size": 184 },
           { "type": 3, "cnt": 29603, "size": 3078544 },
           { "type": 13, "cnt": 6, "size": 48 },
           { "type": 0, "cnt": 34, "size": 544 },
           { "type": 334, "cnt": 41089, "size": 2721600 },
           { "type": 26, "cnt": 329840, "size": 5277440 }] }},
     { "gc": 2, "dsize": 0, "isize": 5628863
       { "dtype": [] }
       { "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 26, "cnt": 96479, "size": 1543664 },
           { "type": 54, "cnt": 17, "size": 2312 },
           { "type": 15, "cnt": 34, "size": 1632 },
           { "type": 330, "cnt": 1, "size": 48 },
           { "type": 1, "cnt": 9, "size": 287 },
           { "type": 3, "cnt": 13, "size": 744 },
           { "type": 13, "cnt": 26, "size": 208 },
           { "type": 334, "cnt": 48123, "size": 3464720 },
           { "type": 30, "cnt": 46, "size": 4728 },
           { "type": 2, "cnt": 72, "size": 605944 },
           { "type": 0, "cnt": 276, "size": 4416 },
           { "type": 331, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 2, "size": 16 }] }}] },
  { "function": "<@main%%SI<@maze,js:3077>:main@maze, "allocs": [
     { "gc": 5, "dsize": 16, "isize": 7977040
       { "dtype": [
           { "type": 26, "cnt": 1, "size": 16 }] }
       { "itype": [
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 13, "cnt": 18558, "size": 148464 },
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 34170, "size": 546720 },
           { "type": 3, "cnt": 12079, "size": 778960 },
           { "type": 26, "cnt": 253026, "size": 4048416 },
           { "type": 334, "cnt": 12543, "size": 779408 },
           { "type": 30, "cnt": 11119, "size": 1276936 },
           { "type": 2, "cnt": 11129, "size": 367352 }] }},
     { "gc": 4, "dsize": 0, "isize": 11351248
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 },
           { "type": 0, "cnt": 52, "size": 832 },
           { "type": 26, "cnt": 539176, "size": 8626816 }] }},
     { "gc": 3, "dsize": 0, "isize": 12025576
       { "dtype": [] }
       { "itype": [
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 30, "cnt": 2, "size": 184 },
           { "type": 3, "cnt": 29603, "size": 3078544 },
           { "type": 13, "cnt": 6, "size": 48 },
           { "type": 0, "cnt": 34, "size": 544 },
           { "type": 334, "cnt": 41089, "size": 2721600 },
           { "type": 26, "cnt": 329840, "size": 5277440 }] }},
     { "gc": 2, "dsize": 10151, "isize": 5618712
       { "dtype": [
           { "type": 54, "cnt": 4, "size": 544 },
           { "type": 15, "cnt": 8, "size": 384 },
           { "type": 1, "cnt": 9, "size": 287 },
           { "type": 3, "cnt": 12, "size": 680 },
           { "type": 13, "cnt": 26, "size": 208 },
           { "type": 334, "cnt": 10, "size": 584 },
           { "type": 30, "cnt": 32, "size": 2800 },
           { "type": 2, "cnt": 32, "size": 920 },
           { "type": 0, "cnt": 230, "size": 3680 },
           { "type": 331, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 2, "size": 16 }] }
       { "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 46, "size": 736 },
           { "type": 54, "cnt": 13, "size": 1768 },
           { "type": 15, "cnt": 26, "size": 1248 },
           { "type": 334, "cnt": 48113, "size": 3464136 },
           { "type": 2, "cnt": 40, "size": 605024 },
           { "type": 30, "cnt": 14, "size": 1928 },
           { "type": 3, "cnt": 1, "size": 64 },
           { "type": 26, "cnt": 96479, "size": 1543664 },
           { "type": 330, "cnt": 1, "size": 48 }] }}] },
  { "function": "#:main@maze, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 7977056
       { "dtype": [] }
       { "itype": [
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 13, "cnt": 18558, "size": 148464 },
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 34170, "size": 546720 },
           { "type": 3, "cnt": 12079, "size": 778960 },
           { "type": 26, "cnt": 253027, "size": 4048432 },
           { "type": 334, "cnt": 12543, "size": 779408 },
           { "type": 30, "cnt": 11119, "size": 1276936 },
           { "type": 2, "cnt": 11129, "size": 367352 }] }},
     { "gc": 4, "dsize": 0, "isize": 11351248
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 },
           { "type": 0, "cnt": 52, "size": 832 },
           { "type": 26, "cnt": 539176, "size": 8626816 }] }},
     { "gc": 3, "dsize": 0, "isize": 12025576
       { "dtype": [] }
       { "itype": [
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 30, "cnt": 2, "size": 184 },
           { "type": 3, "cnt": 29603, "size": 3078544 },
           { "type": 13, "cnt": 6, "size": 48 },
           { "type": 0, "cnt": 34, "size": 544 },
           { "type": 334, "cnt": 41089, "size": 2721600 },
           { "type": 26, "cnt": 329840, "size": 5277440 }] }},
     { "gc": 2, "dsize": 54016, "isize": 5629199
       { "dtype": [
           { "type": 26, "cnt": 1, "size": 16 },
           { "type": 329, "cnt": 1, "size": 144 },
           { "type": 334, "cnt": 72, "size": 4088 },
           { "type": 3, "cnt": 109, "size": 5920 },
           { "type": 15, "cnt": 50, "size": 2224 },
           { "type": 54, "cnt": 25, "size": 3400 },
           { "type": 0, "cnt": 192, "size": 3072 },
           { "type": 30, "cnt": 163, "size": 17872 },
           { "type": 1, "cnt": 101, "size": 2936 },
           { "type": 2, "cnt": 194, "size": 13208 },
           { "type": 13, "cnt": 142, "size": 1136 }] }
       { "itype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 26, "cnt": 96479, "size": 1543664 },
           { "type": 54, "cnt": 17, "size": 2312 },
           { "type": 15, "cnt": 34, "size": 1632 },
           { "type": 1, "cnt": 9, "size": 287 },
           { "type": 3, "cnt": 13, "size": 744 },
           { "type": 13, "cnt": 26, "size": 208 },
           { "type": 334, "cnt": 48123, "size": 3464720 },
           { "type": 30, "cnt": 46, "size": 4728 },
           { "type": 2, "cnt": 72, "size": 605944 },
           { "type": 0, "cnt": 276, "size": 4416 },
           { "type": 331, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 2, "size": 16 },
           { "type": 330, "cnt": 8, "size": 384 }] }}] },
  { "function": "new RegExp, "allocs": [
     { "gc": 2, "dsize": 2075, "isize": 0
       { "dtype": [
           { "type": 2, "cnt": 4, "size": 64 },
           { "type": 365, "cnt": 4, "size": 256 },
           { "type": 45, "cnt": 4, "size": 256 },
           { "type": 1, "cnt": 6, "size": 251 },
           { "type": 0, "cnt": 40, "size": 640 },
           { "type": 3, "cnt": 8, "size": 416 },
           { "type": 13, "cnt": 24, "size": 192 }] }
       { "itype": [] }},
     { "gc": 1, "dsize": 6402, "isize": 0
       { "dtype": [
           { "type": 2, "cnt": 12, "size": 192 },
           { "type": 365, "cnt": 12, "size": 768 },
           { "type": 45, "cnt": 12, "size": 768 },
           { "type": 1, "cnt": 18, "size": 930 },
           { "type": 0, "cnt": 120, "size": 1920 },
           { "type": 3, "cnt": 24, "size": 1248 },
           { "type": 13, "cnt": 72, "size": 576 }] }
       { "itype": [] }}] },
  { "function": "vector->jsarray, "allocs": [
     { "gc": 2, "dsize": 1456, "isize": 0
       { "dtype": [
           { "type": 336, "cnt": 26, "size": 1456 }] }
       { "itype": [] }},
     { "gc": 1, "dsize": 2688, "isize": 0
       { "dtype": [
           { "type": 336, "cnt": 48, "size": 2688 }] }
       { "itype": [] }}] },
  { "function": "js-string->jsstring, "allocs": [
     { "gc": 2, "dsize": 8880, "isize": 0
       { "dtype": [
           { "type": 330, "cnt": 185, "size": 8880 }] }
       { "itype": [] }},
     { "gc": 1, "dsize": 13296, "isize": 0
       { "dtype": [
           { "type": 330, "cnt": 277, "size": 13296 }] }
       { "itype": [] }}] },
  { "function": "&pthread-1036, "allocs": [
     { "gc": 5, "dsize": 520, "isize": 7977056
       { "dtype": [
           { "type": 3, "cnt": 2, "size": 104 },
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 0, "cnt": 22, "size": 352 }] }
       { "itype": [
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 13, "cnt": 18558, "size": 148464 },
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 34170, "size": 546720 },
           { "type": 3, "cnt": 12079, "size": 778960 },
           { "type": 26, "cnt": 253027, "size": 4048432 },
           { "type": 334, "cnt": 12543, "size": 779408 },
           { "type": 30, "cnt": 11119, "size": 1276936 },
           { "type": 2, "cnt": 11129, "size": 367352 }] }},
     { "gc": 4, "dsize": 0, "isize": 11351248
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 },
           { "type": 0, "cnt": 52, "size": 832 },
           { "type": 26, "cnt": 539176, "size": 8626816 }] }},
     { "gc": 3, "dsize": 0, "isize": 12025576
       { "dtype": [] }
       { "itype": [
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 30, "cnt": 2, "size": 184 },
           { "type": 3, "cnt": 29603, "size": 3078544 },
           { "type": 13, "cnt": 6, "size": 48 },
           { "type": 0, "cnt": 34, "size": 544 },
           { "type": 334, "cnt": 41089, "size": 2721600 },
           { "type": 26, "cnt": 329840, "size": 5277440 }] }},
     { "gc": 2, "dsize": 1357485, "isize": 5695242
       { "dtype": [
           { "type": 336, "cnt": 4, "size": 384 },
           { "type": 99, "cnt": 11, "size": 15800 },
           { "type": 1, "cnt": 1309, "size": 40725 },
           { "type": 15, "cnt": 1015, "size": 46904 },
           { "type": 54, "cnt": 494, "size": 67184 },
           { "type": 334, "cnt": 1126, "size": 65760 },
           { "type": 3, "cnt": 1181, "size": 69064 },
           { "type": 0, "cnt": 3780, "size": 60480 },
           { "type": 2, "cnt": 3026, "size": 248304 },
           { "type": 13, "cnt": 938, "size": 7504 },
           { "type": 30, "cnt": 4990, "size": 735376 }] }
       { "itype": [
           { "type": 331, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 2, "size": 16 },
           { "type": 26, "cnt": 96480, "size": 1543680 },
           { "type": 329, "cnt": 1, "size": 144 },
           { "type": 334, "cnt": 48195, "size": 3468808 },
           { "type": 15, "cnt": 84, "size": 3856 },
           { "type": 54, "cnt": 42, "size": 5712 },
           { "type": 30, "cnt": 209, "size": 22600 },
           { "type": 2, "cnt": 270, "size": 619216 },
           { "type": 365, "cnt": 4, "size": 256 },
           { "type": 45, "cnt": 4, "size": 256 },
           { "type": 1, "cnt": 116, "size": 3474 },
           { "type": 0, "cnt": 508, "size": 8128 },
           { "type": 3, "cnt": 130, "size": 7080 },
           { "type": 13, "cnt": 192, "size": 1536 },
           { "type": 336, "cnt": 27, "size": 1552 },
           { "type": 330, "cnt": 185, "size": 8880 }] }},
     { "gc": 1, "dsize": 2812062, "isize": 22386
       { "dtype": [
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 51, "cnt": 1, "size": 16 },
           { "type": 53, "cnt": 1, "size": 136 },
           { "type": 12, "cnt": 1, "size": 64 },
           { "type": 45, "cnt": 1, "size": 64 },
           { "type": 16, "cnt": 24, "size": 192 },
           { "type": 99, "cnt": 23, "size": 32112 },
           { "type": 1, "cnt": 3168, "size": 101921 },
           { "type": 15, "cnt": 2083, "size": 92856 },
           { "type": 2, "cnt": 6312, "size": 922528 },
           { "type": 334, "cnt": 1558, "size": 91336 },
           { "type": 8, "cnt": 14, "size": 560 },
           { "type": 31, "cnt": 141, "size": 3797 },
           { "type": 54, "cnt": 732, "size": 99552 },
           { "type": 30, "cnt": 8628, "size": 1138816 },
           { "type": 0, "cnt": 13626, "size": 218016 },
           { "type": 13, "cnt": 1438, "size": 11504 },
           { "type": 3, "cnt": 1773, "size": 98496 }] }
       { "itype": [
           { "type": 2, "cnt": 12, "size": 192 },
           { "type": 365, "cnt": 12, "size": 768 },
           { "type": 45, "cnt": 12, "size": 768 },
           { "type": 1, "cnt": 18, "size": 930 },
           { "type": 0, "cnt": 120, "size": 1920 },
           { "type": 3, "cnt": 24, "size": 1248 },
           { "type": 13, "cnt": 72, "size": 576 },
           { "type": 336, "cnt": 48, "size": 2688 },
           { "type": 330, "cnt": 277, "size": 13296 }] }}] },
  { "function": "main@maze, "allocs": [
     { "gc": 1, "dsize": 76072, "isize": 0
       { "dtype": [
           { "type": 13, "cnt": 2, "size": 16 },
           { "type": 29, "cnt": 2, "size": 696 },
           { "type": 2, "cnt": 2, "size": 304 },
           { "type": 55, "cnt": 2, "size": 112 },
           { "type": 53, "cnt": 2, "size": 272 },
           { "type": 8, "cnt": 4, "size": 160 },
           { "type": 3, "cnt": 591, "size": 31792 },
           { "type": 30, "cnt": 350, "size": 22104 },
           { "type": 54, "cnt": 2, "size": 272 },
           { "type": 11, "cnt": 2, "size": 320 },
           { "type": 1, "cnt": 14, "size": 728 },
           { "type": 0, "cnt": 1206, "size": 19296 }] }
       { "itype": [] }}] },
  { "function": "%resource@maze, "allocs": [
     { "gc": 1, "dsize": 28, "isize": 0
       { "dtype": [
           { "type": 1, "cnt": 1, "size": 28 }] }
       { "itype": [] }}] },
  { "function": "%call-log@maze, "allocs": [
     { "gc": 1, "dsize": 1192, "isize": 0
       { "dtype": [
           { "type": 2, "cnt": 1, "size": 1192 }] }
       { "itype": [] }}] },
  { "function": "%toplevel@maze, "allocs": [
     { "gc": 1, "dsize": 0, "isize": 1516
       { "dtype": [] }
       { "itype": [
           { "type": 1, "cnt": 1, "size": 28 },
           { "type": 2, "cnt": 1, "size": 1192 },
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 30, "cnt": 1, "size": 48 },
           { "type": 328, "cnt": 1, "size": 184 }] }}] },
  { "function": "%pcache@maze, "allocs": [
     { "gc": 1, "dsize": 296, "isize": 0
       { "dtype": [
           { "type": 0, "cnt": 4, "size": 64 },
           { "type": 30, "cnt": 1, "size": 48 },
           { "type": 328, "cnt": 1, "size": 184 }] }
       { "itype": [] }}] },
  { "function": "eval-init@maze, "allocs": [
     { "gc": 1, "dsize": 964498, "isize": 0
       { "dtype": [
           { "type": 45, "cnt": 12, "size": 768 },
           { "type": 53, "cnt": 5, "size": 680 },
           { "type": 99, "cnt": 20, "size": 4000 },
           { "type": 52, "cnt": 14, "size": 2800 },
           { "type": 7, "cnt": 20, "size": 480 },
           { "type": 2, "cnt": 2082, "size": 105048 },
           { "type": 3, "cnt": 861, "size": 45920 },
           { "type": 0, "cnt": 13740, "size": 219840 },
           { "type": 8, "cnt": 1721, "size": 68840 },
           { "type": 31, "cnt": 1716, "size": 72186 },
           { "type": 30, "cnt": 2508, "size": 160776 },
           { "type": 13, "cnt": 29988, "size": 239904 },
           { "type": 10, "cnt": 18, "size": 3168 },
           { "type": 1, "cnt": 1012, "size": 40088 }] }
       { "itype": [] }}] },
  { "function": "unknown_function, "allocs": [
     { "gc": 5, "dsize": 0, "isize": 7977576
       { "dtype": [] }
       { "itype": [
           { "type": 16, "cnt": 3836, "size": 30688 },
           { "type": 13, "cnt": 18560, "size": 148480 },
           { "type": 336, "cnt": 1, "size": 96 },
           { "type": 0, "cnt": 34192, "size": 547072 },
           { "type": 3, "cnt": 12081, "size": 779064 },
           { "type": 26, "cnt": 253027, "size": 4048432 },
           { "type": 334, "cnt": 12543, "size": 779408 },
           { "type": 30, "cnt": 11119, "size": 1276936 },
           { "type": 2, "cnt": 11130, "size": 367400 }] }},
     { "gc": 4, "dsize": 0, "isize": 11351248
       { "dtype": [] }
       { "itype": [
           { "type": 334, "cnt": 8511, "size": 476616 },
           { "type": 30, "cnt": 8511, "size": 1157496 },
           { "type": 2, "cnt": 8511, "size": 408528 },
           { "type": 3, "cnt": 8512, "size": 680960 },
           { "type": 0, "cnt": 52, "size": 832 },
           { "type": 26, "cnt": 539176, "size": 8626816 }] }},
     { "gc": 3, "dsize": 0, "isize": 12025576
       { "dtype": [] }
       { "itype": [
           { "type": 2, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 118396, "size": 947168 },
           { "type": 30, "cnt": 2, "size": 184 },
           { "type": 3, "cnt": 29603, "size": 3078544 },
           { "type": 13, "cnt": 6, "size": 48 },
           { "type": 0, "cnt": 34, "size": 544 },
           { "type": 334, "cnt": 41089, "size": 2721600 },
           { "type": 26, "cnt": 329840, "size": 5277440 }] }},
     { "gc": 2, "dsize": 0, "isize": 7052727
       { "dtype": [] }
       { "itype": [
           { "type": 331, "cnt": 1, "size": 48 },
           { "type": 16, "cnt": 2, "size": 16 },
           { "type": 26, "cnt": 96480, "size": 1543680 },
           { "type": 329, "cnt": 1, "size": 144 },
           { "type": 365, "cnt": 4, "size": 256 },
           { "type": 45, "cnt": 4, "size": 256 },
           { "type": 99, "cnt": 11, "size": 15800 },
           { "type": 336, "cnt": 31, "size": 1936 },
           { "type": 1, "cnt": 1425, "size": 44199 },
           { "type": 15, "cnt": 1099, "size": 50760 },
           { "type": 330, "cnt": 185, "size": 8880 },
           { "type": 54, "cnt": 536, "size": 72896 },
           { "type": 334, "cnt": 49321, "size": 3534568 },
           { "type": 3, "cnt": 1311, "size": 76144 },
           { "type": 0, "cnt": 4288, "size": 68608 },
           { "type": 2, "cnt": 3296, "size": 867520 },
           { "type": 13, "cnt": 1130, "size": 9040 },
           { "type": 30, "cnt": 5199, "size": 757976 }] }},
     { "gc": 1, "dsize": 745153, "isize": 3876470
       { "dtype": [
           { "type": 7, "cnt": 2, "size": 48 },
           { "type": 55, "cnt": 1, "size": 56 },
           { "type": 15, "cnt": 3, "size": 264 },
           { "type": 53, "cnt": 4, "size": 544 },
           { "type": 8, "cnt": 146, "size": 5840 },
           { "type": 31, "cnt": 140, "size": 7137 },
           { "type": 10, "cnt": 27, "size": 4752 },
           { "type": 2, "cnt": 26, "size": 4488 },
           { "type": 1, "cnt": 1624, "size": 341240 },
           { "type": 0, "cnt": 13006, "size": 208096 },
           { "type": 30, "cnt": 1081, "size": 69120 },
           { "type": 13, "cnt": 12946, "size": 103568 }] }
       { "itype": [
           { "type": 365, "cnt": 12, "size": 768 },
           { "type": 51, "cnt": 1, "size": 16 },
           { "type": 336, "cnt": 49, "size": 2784 },
           { "type": 330, "cnt": 277, "size": 13296 },
           { "type": 12, "cnt": 1, "size": 64 },
           { "type": 16, "cnt": 24, "size": 192 },
           { "type": 15, "cnt": 2083, "size": 92856 },
           { "type": 334, "cnt": 1558, "size": 91336 },
           { "type": 29, "cnt": 2, "size": 696 },
           { "type": 55, "cnt": 2, "size": 112 },
           { "type": 54, "cnt": 734, "size": 99824 },
           { "type": 11, "cnt": 2, "size": 320 },
           { "type": 328, "cnt": 1, "size": 184 },
           { "type": 45, "cnt": 25, "size": 1600 },
           { "type": 53, "cnt": 8, "size": 1088 },
           { "type": 99, "cnt": 43, "size": 36112 },
           { "type": 52, "cnt": 14, "size": 2800 },
           { "type": 7, "cnt": 20, "size": 480 },
           { "type": 2, "cnt": 8409, "size": 1029264 },
           { "type": 3, "cnt": 3248, "size": 177392 },
           { "type": 0, "cnt": 28696, "size": 459136 },
           { "type": 8, "cnt": 1739, "size": 69560 },
           { "type": 31, "cnt": 1857, "size": 75983 },
           { "type": 30, "cnt": 11487, "size": 1321744 },
           { "type": 13, "cnt": 31500, "size": 252000 },
           { "type": 10, "cnt": 18, "size": 3168 },
           { "type": 1, "cnt": 4213, "size": 143695 }] }},
     { "gc": 0, "dsize": 4497507, "isize": 0
       { "dtype": [
           { "type": 56, "cnt": 8, "size": 192 },
           { "type": 54, "cnt": 13, "size": 1768 },
           { "type": 11, "cnt": 6, "size": 960 },
           { "type": 12, "cnt": 3, "size": 192 },
           { "type": 45, "cnt": 50, "size": 3200 },
           { "type": 26, "cnt": 39, "size": 624 },
           { "type": 25, "cnt": 7, "size": 112 },
           { "type": 3, "cnt": 943, "size": 52080 },
           { "type": 15, "cnt": 120, "size": 9448 },
           { "type": 13, "cnt": 96162, "size": 769296 },
           { "type": 10, "cnt": 224, "size": 39424 },
           { "type": 55, "cnt": 2, "size": 112 },
           { "type": 53, "cnt": 51, "size": 6880 },
           { "type": 30, "cnt": 8648, "size": 540196 },
           { "type": 7, "cnt": 554, "size": 13296 },
           { "type": 52, "cnt": 457, "size": 91400 },
           { "type": 99, "cnt": 1267, "size": 235608 },
           { "type": 2, "cnt": 7292, "size": 639456 },
           { "type": 1, "cnt": 4016, "size": 265727 },
           { "type": 0, "cnt": 76928, "size": 1230848 },
           { "type": 8, "cnt": 7079, "size": 283160 },
           { "type": 31, "cnt": 7094, "size": 260544 }] }
       { "itype": [] }}] }]}
}'
]
