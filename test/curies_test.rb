require 'test_helper'

module HALPresenter
  describe Serializer do
    let(:mod) do
      Module.new do
        # Add test classes to an anonymous module prevents these classes
        # to conflict with other tests.
        # self:: forces Ruby to wait to bind the constant.
        # See https://www.ruby-forum.com/t/enumerating-constants-in-anonymous-modules/150537/2
        class self::PresenterA
          extend HALPresenter
          link :foo, curie: :a do
            '/foo/a'
          end
          curie :a, '/a/{rel}'
        end

        class self::PresenterB
          extend HALPresenter
          link :foo, curie: :b do
            '/foo/b'
          end
          curie :b, '/b/{rel}'
        end

        class self::PresenterC
          extend HALPresenter
          link :foo, curie: :c do
            '/foo/c'
          end
          curie :c, '/c/{rel}'
        end

        self::PresenterA.embed :child_b, presenter_class: self::PresenterB do
          'child'
        end
        self::PresenterA.embed :child_c, presenter_class: self::PresenterC do
          ['child', 'child']
        end

        self::PresenterB.embed :child_c, presenter_class: self::PresenterC do
          'child'
        end
      end
    end

    it 'moves curies to the top resource' do
      expected = {
        _links: {
          'a:foo': {
            href: '/foo/a'
          },
          curies: [
            {
              name: 'a',
              href: '/a/{rel}',
              templated: true
            },
            {
              name: 'b',
              href: '/b/{rel}',
              templated: true
            },
            {
              name: 'c',
              href: '/c/{rel}',
              templated: true
            }
          ]
        },
        _embedded: {
          child_b: {
            _links: {
              'b:foo': {
                href: '/foo/b'
              }
            },
            _embedded: {
              child_c: {
                _links: {
                  'c:foo': {
                    href: '/foo/c'
                  }
                }
              }
            }
          },
          child_c: [
            {
              _links: {
                'c:foo': {
                  href: '/foo/c'
                }
              }
            },
            {
              _links: {
                'c:foo': {
                  href: '/foo/c'
                }
              }
            }
          ]
        }
      }

      payload = mod::PresenterA.to_hal
      assert_sameish_hash(expected, JSON.parse(payload))
    end

    it 'rewrites colliding curies' do
      mod::PresenterB.curie :a, '/ba/{rel}'
      mod::PresenterB.link :bar, curie: :a do
        '/foo/ba'
      end

      mod::PresenterC.curie :a, '/ca/{rel}'
      mod::PresenterC.link :bar, curie: :a do
        '/foo/ca'
      end

      expected = {
        _links: {
          'a:foo': {
            href: '/foo/a'
          },
          curies: [
            {
              name: 'a',
              href: '/a/{rel}',
              templated: true
            },
            {
              name: 'b',
              href: '/b/{rel}',
              templated: true
            },
            {
              name: 'a1',
              href: '/ba/{rel}',
              templated: true
            },
            {
              name: 'c',
              href: '/c/{rel}',
              templated: true
            },
            {
              name: 'a0',
              href: '/ca/{rel}',
              templated: true
            },
          ]
        },
        _embedded: {
          child_b: {
            _links: {
              'b:foo': {
                href: '/foo/b'
              },
              'a1:bar': {
                href: '/foo/ba'
              }
            },
            _embedded: {
              child_c: {
                _links: {
                  'c:foo': {
                    href: '/foo/c'
                  },
                  'a0:bar': {
                    href: '/foo/ca'
                  }
                }
              }
            }
          },
          child_c: [
            {
              _links: {
                'c:foo': {
                  href: '/foo/c'
                },
                'a0:bar': {
                  href: '/foo/ca'
                }
              }
            },
            {
              _links: {
                'c:foo': {
                  href: '/foo/c'
                },
                'a0:bar': {
                  href: '/foo/ca'
                }
              }
            }
          ]
        }
      }

      payload = mod::PresenterA.to_hal
      assert_sameish_hash(expected, JSON.parse(payload))
    end
  end
end
