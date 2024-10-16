// Copyright (c) 2024  The Go-CoreLibs Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package slices

import (
	"sync"
)

// Stack is a concurrency-safe manager for a stack of generic items
type Stack[V interface{}] struct {
	d []V // data
	sync.RWMutex
}

// NewStack creates a new Stack instance
func NewStack[V interface{}](items ...V) *Stack[V] {
	return &Stack[V]{
		d: items,
	}
}

// Len returns the size of the Stack
func (s *Stack[V]) Len() (size int) {
	s.RLock()
	defer s.RUnlock()
	return len(s.d)
}

// First returns the first item in the Stack
func (s *Stack[V]) First() (item V, ok bool) {
	s.RLock()
	defer s.RUnlock()
	if ok = len(s.d) > 0; ok {
		item = s.d[0]
	}
	return
}

// Last returns the last item in the Stack
func (s *Stack[V]) Last() (item V, ok bool) {
	s.RLock()
	defer s.RUnlock()
	last := len(s.d) - 1
	if ok = last > -1; ok {
		item = s.d[last]
	}
	return
}

// Get returns the item at the index given
func (s *Stack[V]) Get(idx int) (item V, ok bool) {
	s.RLock()
	defer s.RUnlock()
	if ok = s.Valid(idx); ok {
		item = s.d[idx]
	}
	return
}

// Set overwrites the item at the index given
func (s *Stack[V]) Set(idx int, item V) (ok bool) {
	s.Lock()
	defer s.Unlock()
	if ok = idx > -1 && idx < len(s.d); ok {
		s.d[idx] = item
	}
	return
}

// Push appends the given item to the end of the Stack
func (s *Stack[V]) Push(item V) {
	s.Lock()
	defer s.Unlock()
	s.d = append(s.d, item)
}

// Pop removes and returns the last item in the Stack
func (s *Stack[V]) Pop() (item V, ok bool) {
	s.Lock()
	defer s.Unlock()
	last := len(s.d) - 1
	if ok = last > -1; ok {
		item = s.d[last]
		s.d = s.d[:last]
	}
	return
}

// Shift prepends the given item to the start of the Stack
func (s *Stack[V]) Shift(item V) {
	s.Lock()
	defer s.Unlock()
	s.d = append([]V{item}, s.d...)
}

// Unshift removes and returns the first item in the Stack
func (s *Stack[V]) Unshift() (item V, ok bool) {
	s.Lock()
	defer s.Unlock()
	if ok = len(s.d) > 0; ok {
		item = s.d[0]
		s.d = s.d[1:]
	}
	return
}

// Slice returns the stack as a slice
func (s *Stack[V]) Slice() (items []V) {
	s.RLock()
	defer s.RUnlock()
	items = s.d[:] // new slice?
	return
}

// Valid returns true if the given index is within bounds
func (s *Stack[V]) Valid(idx int) (valid bool) {
	s.RLock()
	defer s.RUnlock()
	valid = idx > -1 && idx < len(s.d)
	return
}
