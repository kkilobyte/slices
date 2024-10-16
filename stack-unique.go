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

// StackUnique is a concurrency-safe manager for a stack of unique generic
// comparable items
type StackUnique[V comparable] struct {
	StackComparable[V]
}

// NewStackUnique creates a new StackUnique instance
func NewStackUnique[V comparable](items ...V) *StackUnique[V] {
	return &StackUnique[V]{
		StackComparable[V]{
			Stack[V]{
				d: items,
			},
		},
	}
}

// Set overwrites the item at the index given
func (s *StackUnique[V]) Set(idx int, item V) (ok bool) {
	if _, present := s.Find(item); !present {
		ok = s.StackComparable.Set(idx, item)
	}
	return
}

// Push appends the given item to the end of the Stack
func (s *StackUnique[V]) Push(item V) {
	if _, present := s.Find(item); !present {
		s.StackComparable.Push(item)
	}
}

// Shift prepends the given item to the start of the Stack
func (s *StackUnique[V]) Shift(item V) {
	if _, present := s.Find(item); !present {
		s.StackComparable.Shift(item)
	}
}
