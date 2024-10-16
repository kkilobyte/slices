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
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestStack(t *testing.T) {

	Convey("NewStack", t, func() {

		s := NewStack[int]()
		So(s, ShouldNotBeNil)
		So(s.Len(), ShouldEqual, 0)

		s.Push(0)

		So(s.Len(), ShouldEqual, 1)
		v, ok := s.First()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, 0)
		v, ok = s.Last()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, 0)
		v, ok = s.Get(0)
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, 0)
		v, ok = s.Get(1)
		So(ok, ShouldBeFalse)
		So(v, ShouldEqual, 0)

		ok = s.Set(0, -1)
		So(ok, ShouldBeTrue)

		v, ok = s.Get(0)
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, -1)

		s.Push(10)

		So(s.Slice(), ShouldEqual, []int{-1, 10})

		v, ok = s.First()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, -1)
		v, ok = s.Last()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, 10)

		s.Shift(2)

		v, ok = s.First()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, 2)
		v, ok = s.Last()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, 10)

		v, ok = s.Pop()
		So(ok, ShouldBeTrue)

		So(v, ShouldEqual, 10)
		v, ok = s.First()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, 2)
		v, ok = s.Last()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, -1)

		v, ok = s.Unshift()
		So(ok, ShouldBeTrue)

		So(v, ShouldEqual, 2)
		v, ok = s.First()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, -1)
		v, ok = s.Last()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, -1)

		v, ok = s.Unshift()
		So(ok, ShouldBeTrue)
		So(v, ShouldEqual, -1)

		So(s.Len(), ShouldEqual, 0)

		v, ok = s.Unshift()
		So(ok, ShouldBeFalse)
		So(v, ShouldEqual, 0)

		v, ok = s.Pop()
		So(ok, ShouldBeFalse)
		So(v, ShouldEqual, 0)

	})

	Convey("NewStackComparable", t, func() {

		s := NewStackComparable[string]()

		s.Push("one")
		So(s.Slice(), ShouldEqual, []string{"one"})
		So(s.Has("one"), ShouldBeTrue)
		So(s.Has("two"), ShouldBeFalse)
		s.Push("two")
		idx, ok := s.Find("two")
		So(ok, ShouldBeTrue)
		So(idx, ShouldEqual, 1)
		So(s.Prune("nope"), ShouldEqual, 0)
		So(s.Prune("two"), ShouldEqual, 1)

	})

	Convey("NewStackUnique", t, func() {

		s := NewStackUnique[string]()

		s.Push("one")
		So(s.Slice(), ShouldEqual, []string{"one"})
		s.Push("two")
		So(s.Slice(), ShouldEqual, []string{"one", "two"})
		s.Shift("this")
		So(s.Slice(), ShouldEqual, []string{"this", "one", "two"})
		So(s.Set(0, "that"), ShouldBeTrue)
		So(s.Slice(), ShouldEqual, []string{"that", "one", "two"})

	})
}
