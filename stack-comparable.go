// Copyright (c) 2024  The Go-Enjin Authors
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

// StackComparable is a concurrency-safe manager for a stack of generic
// comparable items
type StackComparable[V comparable] struct {
	Stack[V]
}

// NewStackComparable creates a new StackComparable instance
func NewStackComparable[V comparable](items ...V) *StackComparable[V] {
	return &StackComparable[V]{
		Stack[V]{
			d: items,
		},
	}
}

// Has returns true if this stack has the search value
func (s *StackComparable[V]) Has(search V) (ok bool) {
	_, ok = s.Find(search)
	return
}

// Find searches the stack for the first instance of the search value
func (s *StackComparable[V]) Find(search V) (index int, ok bool) {
	s.RLock()
	defer s.RUnlock()
	index = -1
	for idx, item := range s.d {
		if ok = item == search; ok {
			index = idx
		}
	}
	return
}

// Prune removes the search values from the stack, returns the number of
// items removed
func (s *StackComparable[V]) Prune(search ...V) (count int) {
	s.RLock()
	defer s.RUnlock()
	if start := len(s.d); start > 0 {
		s.d = Prune(s.d, search...)
		count = start - len(s.d)
	}
	return
}
