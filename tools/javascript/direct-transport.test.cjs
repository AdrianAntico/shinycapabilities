const { test } = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');

function harness() {
  let mutation;
  const observers = [], elements = [], events = [];
  class Element {
    constructor(id, payload = true) {
      this.id = id; this.isConnected = true; this.dataset = { scDirectComponent: 'fixture' };
      this.payload = payload;
    }
    setAttribute() {}
    appendChild() {}
    matches(selector) { return selector === '.sc-direct-component-output'; }
    querySelectorAll(selector) {
      return selector.includes('payload') && this.payload ? [{ parentElement: this,
        textContent: JSON.stringify({component: 'fixture', payload: {value: 1}, revision: 1}) }] : [];
    }
  }
  const document = {readyState: 'complete', body: {}, addEventListener() {},
    getElementById: id => elements.find(e => e.id === id && e.isConnected),
    querySelectorAll: () => elements.filter(e => e.isConnected).flatMap(e => e.querySelectorAll('payload')),
    createElement: () => ({setAttribute() {}})};
  let binding, handler;
  const window = {performance, jQuery: () => ({find() {}}), Shiny: {
    OutputBinding: function() {}, outputBindings: {register: value => {binding = value;}},
    addCustomMessageHandler: (name, value) => {handler = value;}
  }};
  class ResizeObserver {
    constructor(callback) {this.callback = callback; observers.push(this);}
    observe() {} disconnect() {this.disconnected = true;}
  }
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, 'src/direct-transport.js'), 'utf8'), {
    window, document, Element, ResizeObserver, console: {error() {}, warn() {}},
    MutationObserver: class {constructor(callback) {mutation = callback;} observe() {}},
  });
  const transport = window.ShinyCapabilitiesDirectTransport;
  transport.register('fixture', {
    mount: (element, payload) => {events.push(['mount', element]); return {value: 1, model: payload};},
    update: (handle, payload) => {events.push(['update', payload]); return {value: 2, model: payload};},
    resize: handle => events.push(['resize', handle.value]),
    destroy: (handle, element) => events.push(['destroy', element]),
  });
  const add = id => {const e = new Element(id); elements.push(e); return e;};
  const notify = (addedNodes = [], removedNodes = []) => mutation([{addedNodes, removedNodes}]);
  return {transport, add, notify, events, observers, document, window, binding, handler};
}

test('late static insertion mounts and a DOM move preserves the instance', () => {
  const h = harness(), e = h.add('one'); h.notify([e]);
  assert.equal(h.transport.diagnostics().liveInstances, 1);
  h.notify([e], [e]);
  assert.equal(h.transport.diagnostics().mounts, 1);
  assert.equal(h.transport.diagnostics().destroys, 0);
});

test('early patches wait for a full mount and stale patches do not overwrite them', () => {
  const h = harness(), e = h.add('one');
  h.handler({id: 'one', component: 'fixture', revision: 5, payload: {selected: 'b'}});
  h.handler({id: 'one', component: 'fixture', revision: 4, payload: {selected: 'a'}});
  assert.equal(h.transport.diagnostics().mounts, 0);
  h.notify([e]);
  assert.equal(h.transport.diagnostics().mounts, 1);
  assert.equal(h.events.find(e => e[0] === 'update')[1].selected, 'b');
  h.handler({id: 'one', component: 'fixture', revision: 3, payload: {selected: 'c'}});
  assert.equal(h.transport.diagnostics().updates, 1);
});

test('resize observes the replacement handle returned by update', () => {
  const h = harness(), e = h.add('one'); h.notify([e]);
  h.binding.renderValue(e, {component: 'fixture', payload: {value: 2}, revision: 2});
  h.observers[0].callback([{contentRect: {width: 200, height: 100}}]);
  assert.equal(h.events.at(-1)[1], 2);
});

test('same-id replacement retires the old element, then mounts the new identity', () => {
  const h = harness(), old = h.add('one'); h.notify([old]); old.isConnected = false;
  const replacement = h.add('one'); h.notify([replacement], [old]);
  assert.equal(h.transport.diagnostics().mounts, 2);
  assert.equal(h.transport.diagnostics().destroys, 1);
  assert.equal(h.transport.diagnostics().liveInstances, 1);
  h.notify([], [old]);
  assert.equal(h.transport.diagnostics().liveInstances, 1);
  assert.equal(h.observers[0].disconnected, true);
});

test('connected duplicate IDs fail visibly without destroying the original', () => {
  const h = harness(), first = h.add('one'); h.notify([first]);
  const duplicate = h.add('one'); h.notify([duplicate]);
  assert.equal(h.transport.diagnostics().errors, 1);
  assert.equal(h.transport.diagnostics().mounts, 1);
  assert.equal(h.transport.diagnostics().liveInstances, 1);
});

test('repeated mount/unmount returns to zero live instances', () => {
  const h = harness();
  for (let i = 0; i < 100; i++) {
    const e = h.add('one'); h.notify([e]); e.isConnected = false; h.notify([], [e]);
  }
  assert.equal(h.transport.diagnostics().mounts, 100);
  assert.equal(h.transport.diagnostics().destroys, 100);
  assert.equal(h.transport.diagnostics().liveInstances, 0);
  assert.ok(h.observers.every(o => o.disconnected));
});

test('queued operation patches are replayed separately in order', () => {
  const h = harness(), e = h.add('one');
  h.handler({id: 'one', component: 'fixture', revision: 2,
    payload: {patches: [{path: '/first', value: 1}]}});
  h.handler({id: 'one', component: 'fixture', revision: 3,
    payload: {patches: [{path: '/second', value: 2}]}});
  h.notify([e]);
  const paths = h.events.filter(event => event[0] === 'update')
    .flatMap(event => event[1].patches.map(patch => patch.path));
  assert.deepEqual(paths, ['/first', '/second']);
});

test('a full render must not let a previously stale patch through', () => {
  const h = harness(), e = h.add('one'); h.notify([e]);
  h.handler({id: 'one', component: 'fixture', revision: 10, payload: {selected: 'new'}});
  h.binding.renderValue(e, {component: 'fixture', payload: {selected: 'replacement'}, revision: 1});
  const count = h.transport.diagnostics().updates;
  h.handler({id: 'one', component: 'fixture', revision: 9, payload: {selected: 'stale'}});
  assert.equal(h.transport.diagnostics().updates, count);
});

test('a queued patch cannot cross an explicit teardown of the same element', () => {
  const h = harness(), e = h.add('one');
  h.handler({id: 'one', component: 'fixture', revision: 5, payload: {selected: 'old-life'}});
  h.transport.destroyById('one');
  h.notify([e]);
  assert.equal(h.transport.diagnostics().updates, 0);
});
